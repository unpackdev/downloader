package unpacker

import (
	"fmt"

	"github.com/unpackdev/inspector/pkg/machine"
)

const (
	DiscoverState           machine.State = "discover"
	MetadataState           machine.State = "metadata"
	SourceProvidersState    machine.State = "source_providers"
	SourcesState            machine.State = "sources"
	ParserState             machine.State = "parser"
	OpcodesState            machine.State = "opcodes"
	AstState                machine.State = "ast"
	SocialState             machine.State = "social"
	StandardsState          machine.State = "standards"
	ConstructorState        machine.State = "constructor"
	FunctionSignaturesState machine.State = "function_signatures"
	EventSignaturesState    machine.State = "event_signatures"
	TokenState              machine.State = "token"
	FinalState              machine.State = "final"
	ErrorState              machine.State = "error"
	DoneState               machine.State = "done"
)

func GetStateFromString(state string) (machine.State, error) {
	switch state {
	case "discover":
		return DiscoverState, nil
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
	case "token":
		return TokenState, nil
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
