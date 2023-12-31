// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "./ISaleV2.sol";
import "./LibStackPointer.sol";
import "./LibInterpreterState.sol";
import "./LibIntegrityCheck.sol";

/// @title OpISaleV2Reserve
/// @notice Opcode for ISaleV2 `reserve`.
library OpISaleV2Reserve {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 sale_) internal view returns (uint256) {
        return uint256(uint160(ISaleV2(address(uint160(sale_))).reserve()));
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `reserve`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}
