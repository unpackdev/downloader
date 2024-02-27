package subscribers

import (
	"github.com/ethereum/go-ethereum/core/types"
)

// HookType defines the stage at which a hook should be executed relative
// to the block processing. It can be either before (PreHook) or after (PostHook)
// the block is processed.
type HookType string

// String returns the string representation of the HookType.
func (h HookType) String() string {
	return string(h)
}

// PreHook and PostHook constants represent the hook types for pre-processing
// and post-processing of blocks, respectively.
const (
	PreHook  HookType = "pre"  // PreHook indicates the hook will run before block processing.
	PostHook HookType = "post" // PostHook indicates the hook will run after block processing.
)

// BlockHookFn defines the function signature for hooks that process blocks.
// Implementations of this function can modify the block and must return the
// modified block or an error if the processing fails.
type BlockHookFn func(block *types.Block) (*types.Block, error)
