// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./SushiswapIntegration.sol";

contract RebalancingStrategy1 is SushiswapIntegration {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * Rebalance usd and eth such that the eth provider takes all IL risk but receives all excess eth,
     * while usd provider's principal is protected
     */
    function applyRebalance(
        uint256 removedUSDC,
        uint256 removedETH,
        uint256 entryUSDC,
        uint256 entryETH // solhint-disable-line no-unused-vars
    ) internal returns (uint256 exitUSDC, uint256 exitETH) {
        if (removedUSDC > entryUSDC) {
            uint256 deltaUSDC = removedUSDC.sub(entryUSDC);
            exitETH = removedETH.add(_poolSwapExactUSDCForETH(deltaUSDC));
            exitUSDC = entryUSDC;
        } else {
            uint256 deltaUSDC = entryUSDC.sub(removedUSDC);
            uint256 deltaETH = Math.min(removedETH, amountInETHForRequestedOutUSDC(deltaUSDC));
            exitUSDC = removedUSDC.add(_poolSwapExactETHForUSDC(deltaETH));
            exitETH = removedETH.sub(deltaETH);
        }
    }
}
