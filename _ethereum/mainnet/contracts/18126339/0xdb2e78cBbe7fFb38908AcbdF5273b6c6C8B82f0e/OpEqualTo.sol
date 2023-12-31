// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "./LibStackPointer.sol";
import "./LibInterpreterState.sol";
import "./LibIntegrityCheck.sol";

/// @title OpEqualTo
/// @notice Opcode to compare the top two stack values.
library OpEqualTo {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256 c_) {
        // Perhaps surprisingly it seems to require assembly to efficiently get
        // a `uint256` from boolean equality.
        assembly ("memory-safe") {
            c_ := eq(a_, b_)
        }
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}
