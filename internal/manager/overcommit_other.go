//go:build !linux

package manager

func temporarilyAllowMemoryOvercommit() func() {
	return func() {}
}
