//go:build linux

package manager

import (
	"os"
	"strings"
	"sync"

	"github.com/bitxeno/atvloadly/internal/log"
)

var routerOvercommitMu sync.Mutex

// temporarilyAllowMemoryOvercommit lets a constrained OpenWrt router finish one signing job.
// Author: XX. Large IPA resigning can briefly require contiguous memory; the original policy is always restored.
func temporarilyAllowMemoryOvercommit() func() {
	if os.Getenv("ATVLOADLY_ROUTER_OVERCOMMIT") != "1" {
		return func() {}
	}

	routerOvercommitMu.Lock()
	const policyPath = "/proc/sys/vm/overcommit_memory"
	previous, err := os.ReadFile(policyPath)
	if err != nil {
		routerOvercommitMu.Unlock()
		log.Err(err).Msg("Read router memory policy failed; continue with current policy")
		return func() {}
	}
	if strings.TrimSpace(string(previous)) == "1" {
		return func() { routerOvercommitMu.Unlock() }
	}
	if err := os.WriteFile(policyPath, []byte("1\n"), 0644); err != nil {
		routerOvercommitMu.Unlock()
		log.Err(err).Msg("Set temporary router memory policy failed; continue with current policy")
		return func() {}
	}

	return func() {
		if err := os.WriteFile(policyPath, previous, 0644); err != nil {
			log.Err(err).Msg("Restore router memory policy failed")
		}
		routerOvercommitMu.Unlock()
	}
}
