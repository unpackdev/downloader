// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IQuote.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Errors.sol";


abstract contract HashflowExecutor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function swapHashflow(
        uint256 amount,
        IQuote hashflow,
        IQuote.Quote memory quote
    ) external payable {
        if (amount > quote.maxBaseTokenAmount) {
            revert AmountExceedsQuote(amount, quote.maxBaseTokenAmount);
        }
        quote.effectiveBaseTokenAmount = amount;
        if (msg.value == 0) {
            IERC20(quote.baseToken).safeApprove(address(hashflow), quote.effectiveBaseTokenAmount);
        }
        hashflow.tradeSingleHop{value:msg.value}(quote);
    }
}
