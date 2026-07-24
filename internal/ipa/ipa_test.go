package ipa

import (
	"path/filepath"
	"testing"
)

func TestParseFileRejectsMissingArchive(t *testing.T) {
	missingIPA := filepath.Join(t.TempDir(), "missing.ipa")
	if _, err := ParseFile(missingIPA); err == nil {
		t.Fatal("ParseFile accepted a missing IPA archive")
	}
}
