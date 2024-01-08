// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SushiswapIntegration.sol";

abstract contract RebalancingStrategy1 is SushiswapIntegration {
    /**
     * Rebalance usd and eth such that the eth provider takes all IL risk but receives all excess eth,
     * while usd provider's principal is protected
     */
    function applyRebalance(
        uint256 removedUSDC,
        uint256 removedETH,
        uint256 entryUSDC,
        uint256 //entryETH
    ) internal returns (uint256 exitUSDC, uint256 exitETH) {
        if (removedUSDC > entryUSDC) {
            uint256 deltaUSDC = removedUSDC - entryUSDC;
            exitETH = removedETH + _swapExactUSDCForETH(deltaUSDC);
            exitUSDC = entryUSDC;
        } else {
            uint256 deltaUSDC = entryUSDC - removedUSDC;
            uint256 deltaETH = Math.min(removedETH, amountInETHForRequestedOutUSDC(deltaUSDC));
            exitUSDC = removedUSDC + _swapExactETHForUSDC(deltaETH);
            exitETH = removedETH - deltaETH;
        }
    }
}
