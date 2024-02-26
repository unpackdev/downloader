package subscribers

import (
	"github.com/ethereum/go-ethereum/core/types"
)

type HookType string

func (h HookType) String() string {
	return string(h)
}

const (
	PreHook  HookType = "pre"
	PostHook HookType = "post"
)

type BlockHookFn func(block *types.Block) (*types.Block, error)
