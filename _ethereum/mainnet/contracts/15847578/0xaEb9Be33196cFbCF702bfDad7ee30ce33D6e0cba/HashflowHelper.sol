// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Hashflow.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Errors.sol";

/**
 * @title HashflowHelper
 * @notice Helper that performs onchain calculation required to call a Haashflow contract and returns corresponding caller and data
 */
abstract contract HashflowHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function swapHashflow(
        uint256 amount,
        IQuote hashflow,
        IQuote.RFQTQuote memory quote
    ) external pure returns (address target, bytes memory data) {
        if (amount > quote.maxBaseTokenAmount) {
            revert AmountExceedsQuote(amount, quote.maxBaseTokenAmount);
        }
        quote.effectiveBaseTokenAmount = amount;
        bytes memory resultData = abi.encodeWithSelector(hashflow.tradeSingleHop.selector, quote);
        return (address(hashflow), resultData);
    }
}
