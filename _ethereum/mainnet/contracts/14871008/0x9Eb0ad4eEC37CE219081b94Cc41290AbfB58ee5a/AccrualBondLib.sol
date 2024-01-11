// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./FixedPointMathLib.sol";

library AccrualBondLib {

    struct Position {
        uint256 owed;
        uint256 redeemed;
        uint256 creation;
    }

    function getRedeemAmountOut(
        uint256 owed,
        uint256 redeemed,
        uint256 creation,
        uint256 term
    ) internal view returns (uint256) {
        
        uint256 elapsed = block.timestamp - creation;

        if (elapsed > term) elapsed = term;

        return FixedPointMathLib.fmul(owed, elapsed, term) - redeemed;
    }
}