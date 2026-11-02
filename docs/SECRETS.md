# Secrets

This repo is public, so no token or key ever goes into git.

## Where the TMDB token lives

```
Configs/Secrets.xcconfig          your machine only, ignored by git
        │  TMDB_ACCESS_TOKEN = eyJ...
        ▼
Configs/Base.xcconfig             #include? "Secrets.xcconfig"
        ▼
MovieDB/App/Info.plist            TMDBAccessToken = $(TMDB_ACCESS_TOKEN)
        ▼
MDBTMDBConfiguration              reads it at launch
        ▼
MDBAPIClient                      Authorization: Bearer <token>
```

- The token is the **API Read Access Token** (v4). It is sent in a header, never in a URL, so it doesn't end up in logs, caches or crash reports.
- `Configs/Secrets.example.xcconfig` is committed with an empty value. `Scripts/bootstrap.sh` copies it to `Secrets.xcconfig` for you.
- If the token is missing, the app shows a setup screen instead of crashing.

## Guard rails

- `.gitignore` lists `Configs/Secrets.xcconfig`.
- `Scripts/check-secrets.sh` runs as a pre-commit hook, installed by `Scripts/install-hooks.sh`. It blocks a commit if:
  - the secrets file is staged, or
  - anything looks like a TMDB v3 key or a v4 token, or
  - gitleaks finds anything.
- CI runs gitleaks on every push and pull request.
- The network log and the cURL helper always print `Bearer <redacted>`.
- `MDBTMDBConfiguration`'s description only says whether a token is set and how long it is.
- GitHub secret scanning and push protection are on for this repo.

## Things to know

**A token shipped inside an app can be extracted.** Anyone with the `.ipa` can find it in `Info.plist`.
That is acceptable for TMDB's read-only token, but don't reuse this pattern for a key that can write data or costs money. Those belong on a server you control.

**Rotating the token**
1. Go to [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api) and regenerate the key. This also changes the Read Access Token.
2. Paste the new token into `Configs/Secrets.xcconfig`.
3. Clean the build folder (Shift+Cmd+K) and run again. Xcode caches Info.plist values.

**If a token gets committed**
1. Rotate it first. Removing it from git history does not help once it has been pushed, because forks and clones keep the old commits.
2. Then remove the file and commit again.
3. Only rewrite history if you really need the old commits gone.
