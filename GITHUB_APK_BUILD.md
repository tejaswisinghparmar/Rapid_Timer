# Build APK In GitHub Actions

## 1) Initialize git and push to GitHub

Run these commands in this project folder:

```bash
git init
git branch -M main
git add .
git commit -m "Initial commit with Flutter stopwatch"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

## 2) Trigger the workflow

A push to `main` starts the workflow automatically.

You can also trigger manually:
- Open your repo on GitHub
- Go to **Actions**
- Select **Build Flutter APK**
- Click **Run workflow**

## 3) Download the APK

- Open the completed workflow run
- In **Artifacts**, download `app-release-apk`
- Unzip it to get `app-release.apk`

## 4) Install on Android phone

- Copy `app-release.apk` to your phone
- Open it from Files app
- If prompted, enable **Install unknown apps** for that app
- Tap **Install**

## Notes

- Workflow file: `.github/workflows/flutter-apk.yml`
- APK output in CI: `build/app/outputs/flutter-apk/app-release.apk`
