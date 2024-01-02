// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Hashflow.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @title HashflowHelper
 * @notice Helper that performs onchain calculation required to call a Haashflow contract and returns corresponding caller and data
 */
abstract contract HashflowHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function swapHashflow(
        uint256 amount,
        IHashflowRouter hashflow,
        IHashflowRouter.RFQTQuote memory quote
    ) external pure returns (address target, address sourceTokenInteractionTarget, uint256 actualSwapAmount, bytes memory data) {
        if (amount > quote.baseTokenAmount) {
            quote.effectiveBaseTokenAmount = quote.baseTokenAmount;
        } else {
            quote.effectiveBaseTokenAmount = amount;
        }
        bytes memory resultData = abi.encodeCall(hashflow.tradeRFQT, quote);
        return (address(hashflow), address(hashflow), quote.effectiveBaseTokenAmount, resultData);
    }
}
