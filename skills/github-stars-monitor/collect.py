#!/usr/bin/env python3
"""
GitHub Stars & Forks Collector for your skills repo.

Fetches all stargazers and forkers for monitored repos,
compares against processed state, outputs NEW entries with profiles.

Usage:
    GITHUB_TOKEN=ghp_xxx python3 collect.py [--state /path/to/state.json]

Output: JSON to stdout with new stargazers/forkers and their profiles.
State file is updated in-place after successful collection.
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone

def _load_repos_from_env():
    """REPOS comes from MONITORED_REPOS env (comma-separated owner/repo entries)."""
    raw = os.environ.get("MONITORED_REPOS", "")
    return [r.strip() for r in raw.split(",") if r.strip()]


# Populated in main() once env vars are loaded.
REPOS = []

DEFAULT_STATE_PATH = os.path.expanduser(
    "~/.openclaw/workspace/memory/github-stars.json"
)

MAX_PROCESSED_PER_REPO = 2000  # trim older entries beyond this


def github_get(url, token, accept=None):
    """GET request to GitHub API with auth and pagination support."""
    headers = {"Authorization": f"token {token}", "User-Agent": "your skills repo-Stars-Monitor"}
    if accept:
        headers["Accept"] = accept
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode())
            # Parse Link header for pagination
            link_header = resp.headers.get("Link", "")
            next_url = None
            if link_header:
                for part in link_header.split(","):
                    if 'rel="next"' in part:
                        next_url = part.split("<")[1].split(">")[0]
            return data, next_url
    except urllib.error.HTTPError as e:
        if e.code == 403:
            print(f"Rate limited or forbidden: {url}", file=sys.stderr)
            return [], None
        if e.code == 404:
            print(f"Repo not found: {url}", file=sys.stderr)
            return [], None
        raise
    except urllib.error.URLError as e:
        print(f"Network error: {e}", file=sys.stderr)
        return [], None


def fetch_all_pages(base_url, token, accept=None, max_pages=50):
    """Fetch all pages from a paginated GitHub API endpoint."""
    all_items = []
    url = base_url
    page = 0
    while url and page < max_pages:
        items, next_url = github_get(url, token, accept=accept)
        if not items:
            break
        all_items.extend(items)
        url = next_url
        page += 1
        if page < max_pages and url:
            time.sleep(0.5)  # be nice to API
    return all_items


def fetch_stargazers(repo, token):
    """Fetch all stargazers for a repo (with star timestamps)."""
    url = f"https://api.github.com/repos/{repo}/stargazers?per_page=100"
    items = fetch_all_pages(url, token, accept="application/vnd.github.star+json")
    result = []
    for item in items:
        user = item.get("user", {})
        result.append({
            "username": user.get("login", ""),
            "starred_at": item.get("starred_at", ""),
            "avatar_url": user.get("avatar_url", ""),
        })
    return result


def fetch_forkers(repo, token):
    """Fetch all forkers for a repo."""
    url = f"https://api.github.com/repos/{repo}/forks?per_page=100&sort=newest"
    items = fetch_all_pages(url, token)
    result = []
    for item in items:
        owner = item.get("owner", {})
        result.append({
            "username": owner.get("login", ""),
            "forked_at": item.get("created_at", ""),
            "avatar_url": owner.get("avatar_url", ""),
        })
    return result


def fetch_user_profile(username, token):
    """Fetch detailed GitHub profile for a user."""
    url = f"https://api.github.com/users/{username}"
    profile, _ = github_get(url, token)
    if not profile:
        return {}
    return {
        "username": username,
        "name": profile.get("name"),
        "company": profile.get("company"),
        "bio": profile.get("bio"),
        "email": profile.get("email"),
        "blog": profile.get("blog"),
        "location": profile.get("location"),
        "public_repos": profile.get("public_repos", 0),
        "followers": profile.get("followers", 0),
        "following": profile.get("following", 0),
        "created_at": profile.get("created_at"),
        "twitter_username": profile.get("twitter_username"),
        "html_url": profile.get("html_url"),
    }


def load_state(path):
    """Load state from JSON file, or return empty state."""
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return {
        "processed_stargazers": {},
        "processed_forkers": {},
        "last_checked": None,
        "stats_history": [],
    }


def save_state(state, path):
    """Save state to JSON file atomically."""
    # Trim processed lists
    for repo in state.get("processed_stargazers", {}):
        users = state["processed_stargazers"][repo]
        if len(users) > MAX_PROCESSED_PER_REPO:
            state["processed_stargazers"][repo] = users[-MAX_PROCESSED_PER_REPO:]
    for repo in state.get("processed_forkers", {}):
        users = state["processed_forkers"][repo]
        if len(users) > MAX_PROCESSED_PER_REPO:
            state["processed_forkers"][repo] = users[-MAX_PROCESSED_PER_REPO:]

    tmp_path = path + ".tmp"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(tmp_path, "w") as f:
        json.dump(state, f, indent=2)
    os.replace(tmp_path, path)


def _load_gateway_env():
    env_path = os.path.expanduser("~/.openclaw/gateway.env")
    if not os.path.exists(env_path):
        return
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key not in os.environ:
                os.environ[key] = value


def main():
    if not os.environ.get("GITHUB_TOKEN"):
        _load_gateway_env()
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        print(json.dumps({"error": "GITHUB_TOKEN env var not set"}))
        sys.exit(1)

    global REPOS
    REPOS = _load_repos_from_env()
    if not REPOS:
        print(json.dumps({"error": "MONITORED_REPOS env var not set (expected comma-separated owner/repo list)"}))
        sys.exit(1)

    state_path = DEFAULT_STATE_PATH
    if "--state" in sys.argv:
        idx = sys.argv.index("--state")
        if idx + 1 < len(sys.argv):
            state_path = sys.argv[idx + 1]

    state = load_state(state_path)
    now = datetime.now(timezone.utc).isoformat()

    new_stargazers = []
    new_forkers = []
    repo_stats = {}

    for repo in REPOS:
        known_stars = set(state.get("processed_stargazers", {}).get(repo, []))
        known_forks = set(state.get("processed_forkers", {}).get(repo, []))

        # Fetch all stargazers
        stargazers = fetch_stargazers(repo, token)
        all_star_usernames = [s["username"] for s in stargazers if s["username"]]

        # Fetch all forkers
        forkers = fetch_forkers(repo, token)
        all_fork_usernames = [f["username"] for f in forkers if f["username"]]

        # Find new ones
        for s in stargazers:
            if s["username"] and s["username"] not in known_stars:
                new_stargazers.append({"repo": repo, **s})

        for f in forkers:
            if f["username"] and f["username"] not in known_forks:
                new_forkers.append({"repo": repo, **f})

        repo_stats[repo] = {
            "total_stars": len(stargazers),
            "total_forks": len(forkers),
            "new_stars": len([s for s in stargazers if s["username"] not in known_stars]),
            "new_forks": len([f for f in forkers if f["username"] not in known_forks]),
        }

        # Update state with ALL known users (not just new)
        state.setdefault("processed_stargazers", {})[repo] = list(
            known_stars | set(all_star_usernames)
        )
        state.setdefault("processed_forkers", {})[repo] = list(
            known_forks | set(all_fork_usernames)
        )

    # Fetch profiles for new stargazers and forkers (deduplicate by username)
    seen_usernames = set()
    profiles = {}
    all_new = new_forkers + new_stargazers  # forkers first (stronger signal)
    for entry in all_new:
        username = entry["username"]
        if username in seen_usernames:
            continue
        seen_usernames.add(username)
        profile = fetch_user_profile(username, token)
        if profile:
            profiles[username] = profile
            time.sleep(0.3)  # rate limit courtesy

    # Attach profiles
    for s in new_stargazers:
        s["profile"] = profiles.get(s["username"], {})
    for f in new_forkers:
        f["profile"] = profiles.get(f["username"], {})

    # Update state
    state["last_checked"] = now

    # Save state BEFORE outputting (so even if agent processing fails, state is saved)
    save_state(state, state_path)

    # Output results
    output = {
        "timestamp": now,
        "new_stargazers": new_stargazers,
        "new_forkers": new_forkers,
        "repo_stats": repo_stats,
        "total_new": len(new_stargazers) + len(new_forkers),
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
