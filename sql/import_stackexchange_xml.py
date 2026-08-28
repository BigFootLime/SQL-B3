#!/usr/bin/env python3
"""Convertit le dump XML Coffee Stack Exchange en CSV chargeables par psql.

Le script ne charge rien dans PostgreSQL. Il transforme seulement les XML et
signale les lignes orphelines du dump public (utilisateurs ou posts supprimes).
"""

from __future__ import annotations

import argparse
import csv
import re
import xml.etree.ElementTree as ET
from pathlib import Path


NULL = ""
TAG_RE = re.compile(r"<([^<>]+)>")


def rows(path: Path):
    for _, element in ET.iterparse(path, events=("end",)):
        if element.tag == "row":
            yield dict(element.attrib)
        element.clear()


def value(record: dict[str, str], key: str, default: str = NULL) -> str:
    return record.get(key, default)


def extract_tags(raw_tags: str) -> list[str]:
    """Supporte les deux formats rencontres dans les dumps Stack Exchange."""
    if raw_tags.startswith("|"):
        return [tag for tag in raw_tags.split("|") if tag]
    return TAG_RE.findall(raw_tags)


def write_csv(path: Path, header: list[str], records):
    count = 0
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(header)
        for record in records:
            writer.writerow(record)
            count += 1
    return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="Dossier contenant les fichiers XML")
    parser.add_argument("output", type=Path, help="Dossier de sortie des CSV")
    args = parser.parse_args()

    source = args.source.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)

    xml_users = list(rows(source / "Users.xml"))
    xml_posts = list(rows(source / "Posts.xml"))
    xml_comments = list(rows(source / "Comments.xml"))
    xml_votes = list(rows(source / "Votes.xml"))
    xml_badges = list(rows(source / "Badges.xml"))
    xml_tags = list(rows(source / "Tags.xml"))

    user_ids = {int(r["Id"]) for r in xml_users}
    referenced_user_ids = {
        int(r[key])
        for data, key in (
            (xml_posts, "OwnerUserId"),
            (xml_posts, "LastEditorUserId"),
            (xml_comments, "UserId"),
            (xml_votes, "UserId"),
            (xml_badges, "UserId"),
        )
        for r in data
        if r.get(key)
    }
    missing_user_ids = sorted(referenced_user_ids - user_ids)

    def user_records():
        for r in xml_users:
            yield [
                value(r, "Id"), value(r, "Reputation", "1"), value(r, "CreationDate"),
                value(r, "DisplayName"), value(r, "LastAccessDate"), value(r, "Location"),
                value(r, "AboutMe"), value(r, "Views", "0"), value(r, "UpVotes", "0"),
                value(r, "DownVotes", "0"), value(r, "AccountId"),
            ]
        for user_id in missing_user_ids:
            yield [
                str(user_id), "1", "2015-01-01T00:00:00", f"[utilisateur supprime {user_id}]",
                "2015-01-01T00:00:00", NULL, NULL, "0", "0", "0", NULL,
            ]

    counts: dict[str, int] = {}
    counts["users"] = write_csv(
        output / "users.csv",
        ["id", "reputation", "creation_date", "display_name", "last_access_date", "location", "about_me", "views", "up_votes", "down_votes", "account_id"],
        user_records(),
    )

    post_dates = {int(r["Id"]): r["CreationDate"] for r in xml_posts}
    post_ids = set(post_dates)
    counts["post_ids"] = write_csv(
        output / "post_ids.csv",
        ["id", "creation_date"],
        ([r["Id"], r["CreationDate"]] for r in xml_posts),
    )

    counts["posts"] = write_csv(
        output / "posts.csv",
        [
            "id", "post_type_id", "parent_id", "accepted_answer_id", "creation_date",
            "score", "view_count", "body", "owner_user_id", "last_editor_user_id",
            "last_edit_date", "last_activity_date", "title", "tags", "answer_count",
            "comment_count", "favorite_count", "community_owned_date",
        ],
        (
            [
                value(r, "Id"), value(r, "PostTypeId"), value(r, "ParentId"),
                value(r, "AcceptedAnswerId"), value(r, "CreationDate"), value(r, "Score", "0"),
                value(r, "ViewCount", "0"), value(r, "Body"), value(r, "OwnerUserId"),
                value(r, "LastEditorUserId"), value(r, "LastEditDate"),
                value(r, "LastActivityDate"), value(r, "Title"), value(r, "Tags"),
                value(r, "AnswerCount", "0"), value(r, "CommentCount", "0"),
                value(r, "FavoriteCount", "0"), value(r, "CommunityOwnedDate"),
            ]
            for r in xml_posts
        ),
    )

    counts["comments"] = write_csv(
        output / "comments.csv",
        ["id", "post_id", "score", "text", "creation_date", "user_id"],
        (
            [value(r, "Id"), value(r, "PostId"), value(r, "Score", "0"), value(r, "Text"), value(r, "CreationDate"), value(r, "UserId")]
            for r in xml_comments
            if int(r["PostId"]) in post_ids
        ),
    )

    orphan_votes = [r for r in xml_votes if int(r["PostId"]) not in post_ids]
    counts["votes"] = write_csv(
        output / "votes.csv",
        ["id", "post_id", "vote_type_id", "creation_date", "user_id", "bounty_amount"],
        (
            [value(r, "Id"), value(r, "PostId"), value(r, "VoteTypeId"), value(r, "CreationDate"), value(r, "UserId"), value(r, "BountyAmount")]
            for r in xml_votes
            if int(r["PostId"]) in post_ids
        ),
    )

    counts["badges"] = write_csv(
        output / "badges.csv",
        ["id", "user_id", "name", "date", "class", "tag_based"],
        (
            [value(r, "Id"), value(r, "UserId"), value(r, "Name"), value(r, "Date"), value(r, "Class"), value(r, "TagBased", "False")]
            for r in xml_badges
        ),
    )

    tag_by_name = {r["TagName"]: int(r["Id"]) for r in xml_tags}
    counts["tags"] = write_csv(
        output / "tags.csv",
        ["id", "tag_name", "count", "excerpt_post_id", "wiki_post_id"],
        (
            [value(r, "Id"), value(r, "TagName"), value(r, "Count", "0"), value(r, "ExcerptPostId"), value(r, "WikiPostId")]
            for r in xml_tags
        ),
    )

    post_tag_records: list[list[str]] = []
    missing_tag_names: set[str] = set()
    for post in xml_posts:
        for tag_name in extract_tags(post.get("Tags", "")):
            tag_id = tag_by_name.get(tag_name)
            if tag_id is None:
                missing_tag_names.add(tag_name)
                continue
            post_tag_records.append([post["Id"], str(tag_id)])
    counts["post_tags"] = write_csv(
        output / "post_tags.csv",
        ["post_id", "tag_id"],
        post_tag_records,
    )

    print("Conversion terminee")
    for name, count in counts.items():
        print(f"  {name}: {count}")
    print(f"  utilisateurs de reference recrees: {len(missing_user_ids)} {missing_user_ids}")
    print(f"  votes orphelins ignores: {len(orphan_votes)}")
    print(f"  tags absents ignores: {len(missing_tag_names)} {sorted(missing_tag_names)}")


if __name__ == "__main__":
    main()
