# flutter_sqlite_document_search

Local SQLite embeddings with [sqlite-vec](https://github.com/asg017/sqlite-vec).

1. Create env.json - [Get an API key](https://aistudio.google.com/app/apikey)

```json
{
  "GOOGLE_AI_API_KEY": "YOUR_GOOGLE_API_KEY_HERE",
}
```

2. Run the following:

```bash
make deps
make build_files
make run_macos
```

3. Add markdown and text files in the app to query against.

## Platforms Verified

- [X] Web
- [X] MacOS
- [X] iOS
- [X] Android
- [X] Linux
- [X] Windows
