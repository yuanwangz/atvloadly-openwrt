package service

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/bitxeno/atvloadly/internal/app"
	"github.com/bitxeno/atvloadly/internal/model"
)

func TestSaveRemoteAppKeepsOnlySourceURL(t *testing.T) {
	workDir := t.TempDir()
	app.Config = &app.Configuration{}
	app.Config.Server.DataDir = workDir
	app.Config.Db.FileName = "app.db"
	if err := app.InitDb(app.Config); err != nil {
		t.Fatalf("InitDb returned error: %v", err)
	}

	temporaryIPA := filepath.Join(workDir, "downloaded.ipa")
	if err := os.WriteFile(temporaryIPA, []byte("temporary ipa"), 0600); err != nil {
		t.Fatalf("WriteFile returned error: %v", err)
	}

	saved, err := SaveApp(model.InstalledApp{
		IpaName:          "Remote App",
		IpaPath:          temporaryIPA,
		SourceURL:        "https://example.com/RemoteApp.ipa",
		BundleIdentifier: "example.remote-app",
		Account:          "user@example.com",
		UDID:             "test-device",
	})
	if err != nil {
		t.Fatalf("SaveApp returned error: %v", err)
	}
	if saved.IpaPath != "" {
		t.Fatalf("saved IPA path = %q, want empty path for remote source", saved.IpaPath)
	}
	if saved.SourceURL != "https://example.com/RemoteApp.ipa" {
		t.Fatalf("saved source URL = %q", saved.SourceURL)
	}
	if _, err := os.Stat(temporaryIPA); err != nil {
		t.Fatalf("SaveApp moved temporary IPA instead of leaving cleanup to the install task: %v", err)
	}
	if _, err := os.Stat(filepath.Join(workDir, "ipa", "1", "app.ipa")); !os.IsNotExist(err) {
		t.Fatalf("remote source unexpectedly persisted an IPA file: %v", err)
	}
}
