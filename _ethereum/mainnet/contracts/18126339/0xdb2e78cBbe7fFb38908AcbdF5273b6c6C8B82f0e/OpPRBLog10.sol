// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import "./LibIntegrityCheck.sol";
import "./LibInterpreterState.sol";
import "./Math.sol";

library OpPRBLog10 {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_) internal pure returns (uint256) {
        return UD60x18.unwrap(log10(UD60x18.wrap(a_)));
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
