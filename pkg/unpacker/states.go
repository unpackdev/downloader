package unpacker

import (
	"fmt"

	"github.com/unpackdev/trader/pkg/machine"
)

const (
	DiscoverState           machine.State = "discover"
	AccountState            machine.State = "account"
	MetadataState           machine.State = "metadata"
	SourceProvidersState    machine.State = "source_providers"
	ParserState             machine.State = "parser"
	SourcesState            machine.State = "sources"
	OpcodesState            machine.State = "opcodes"
	AstState                machine.State = "ast"
	SocialState             machine.State = "social"
	StandardsState          machine.State = "standards"
	ConstructorState        machine.State = "constructor"
	FunctionSignaturesState machine.State = "function_signatures"
	EventSignaturesState    machine.State = "event_signatures"
	VerifyState             machine.State = "verify"
	AuditState              machine.State = "audit"
	TokenState              machine.State = "token"
	LiquidityState          machine.State = "liquidity"
	SafetyState             machine.State = "safety"
	SimulatorState          machine.State = "simulator"
	FinalState              machine.State = "final"
	ErrorState              machine.State = "error"
	DoneState               machine.State = "done"
)

func GetStateFromString(state string) (machine.State, error) {
	switch state {
	case "discover":
		return DiscoverState, nil
	case "account":
		return AccountState, nil
	case "metadata":
		return MetadataState, nil
	case "source_providers":
		return SourceProvidersState, nil
	case "parser":
		return ParserState, nil
	case "sources":
		return SourcesState, nil
	case "opcodes":
		return OpcodesState, nil
	case "ast":
		return AstState, nil
	case "social":
		return SocialState, nil
	case "standards":
		return StandardsState, nil
	case "constructor":
		return ConstructorState, nil
	case "function_signatures":
		return FunctionSignaturesState, nil
	case "event_signatures":
		return EventSignaturesState, nil
	case "verify":
		return VerifyState, nil
	case "audit":
		return AuditState, nil
	case "token":
		return TokenState, nil
	case "liquidity":
		return LiquidityState, nil
	case "safety":
		return SafetyState, nil
	case "simulator":
		return SimulatorState, nil
	case "final":
		return FinalState, nil
	case "error":
		return ErrorState, nil
	case "done":
		return DoneState, nil
	default:
		return "", fmt.Errorf("unknown state '%s' provided", state)
	}
}
