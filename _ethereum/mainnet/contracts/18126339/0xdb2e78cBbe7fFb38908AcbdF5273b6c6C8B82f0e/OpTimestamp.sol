// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "./LibStackPointer.sol";
import "./LibInterpreterState.sol";
import "./LibIntegrityCheck.sol";

/// @title OpTimestamp
/// @notice Opcode for getting the current timestamp.
library OpTimestamp {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.push(stackTop_);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.push(block.timestamp);
    }
}
