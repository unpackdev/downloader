// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./IPancakeRouter02.sol";
import "./IUniswapV3SwapRouter.sol";
import "./IPeripheryState.sol";
import "./IWETH9.sol";
import "./Order.sol";
import "./FullMath.sol";

abstract contract ExternalSwapRouterUpgradeable is Initializable {
    using SafeERC20 for IERC20;

    address public pancakeswapRouter; // legacy variable, not removing it just to maintain the storage layout of upgradable contract

    event ExternalSwap(
        address externalRouter,
        address sender,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    error OrderExpired();
    error ZeroFlexibleAmount();
    error ExternalCallFailed(address, bytes4);
    error InvalidZeroInputAmount();
    error InvalidZeroOutputAmount();
    error NotEnoughTokenOutReceived();
    error EthTransferFail();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function calculateTokenAmount(
        uint256 flexibleAmount,
        Orders.Order memory _order
    ) private pure returns (uint256, uint256) {
        uint256 buyerTokenAmount = _order.buyerTokenAmount;
        uint256 sellerTokenAmount = _order.sellerTokenAmount;

        if (sellerTokenAmount == 0 || buyerTokenAmount == 0 || flexibleAmount == 0) {
            revert InvalidZeroInputAmount();
        }

        if (flexibleAmount < sellerTokenAmount) {
            buyerTokenAmount = FullMath.mulDiv(flexibleAmount, buyerTokenAmount, sellerTokenAmount);
            sellerTokenAmount = flexibleAmount;
        }

        if (buyerTokenAmount == 0) {
            revert InvalidZeroOutputAmount();
        }
        return (buyerTokenAmount, sellerTokenAmount);
    }

    function externalSwap(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient,
        address payer,
        bytes memory fallbackSwapCalldata
    ) internal returns (uint256) {
        if (order.deadlineTimestamp <= block.timestamp) {
            revert OrderExpired();
        }

        if (flexibleAmount == 0) {
            revert ZeroFlexibleAmount();
        }

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(flexibleAmount, order);

        prepareTokenIn(IERC20(order.sellerToken), payer, sellerTokenAmount, order.buyer);

        uint256 routerTokenOutBalanceBefore = IERC20(order.buyerToken).balanceOf(address(this));
        uint256 recipientTokenOutBalanceBefore = IERC20(order.buyerToken).balanceOf(recipient);

        {
            // call to external contract
            (bool success, ) = order.buyer.call(fallbackSwapCalldata);
            if (!success) {
                revert ExternalCallFailed(order.buyer, bytes4(fallbackSwapCalldata));
            }
        }

        uint256 amountOut;
        {
            // assume the tokenOut is sent to "recipient" by external call directly
            uint256 recipientDiff = IERC20(order.buyerToken).balanceOf(recipient) - recipientTokenOutBalanceBefore;
            uint256 routerDiff = IERC20(order.buyerToken).balanceOf(address(this)) - routerTokenOutBalanceBefore;

            // if routerDiff is more, router has the tokens, so router transfers it out to recipient
            if (recipientDiff < routerDiff) {
                IERC20(order.buyerToken).safeTransfer(recipient, routerDiff);
                amountOut = IERC20(order.buyerToken).balanceOf(recipient) - recipientTokenOutBalanceBefore;
            } else {
                // otherwise, recipient has the tokens, so we can use recipientDiff
                amountOut = recipientDiff;
            }

            // amountOut is always the difference in after - before of recipient balance, to account for fee on transfer tokens
            if (amountOut < buyerTokenAmount) {
                revert NotEnoughTokenOutReceived();
            }
        }

        emitExternalSwapEvent(order, int256(sellerTokenAmount), (-1 * int256(amountOut)), order.quoteId);

        return amountOut;
    }

    function emitExternalSwapEvent(
        Orders.Order memory order,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    ) private {
        emit ExternalSwap(order.buyer, order.caller, order.sellerToken, order.buyerToken, amountIn, amountOut, quoteId);
    }

    function prepareTokenIn(IERC20 tokenIn, address payer, uint256 tokenAmount, address externalRouter) internal {
        if (payer != address(this)) {
            tokenIn.safeTransferFrom(payer, address(this), tokenAmount);
        }
        tokenIn.safeIncreaseAllowance(externalRouter, tokenAmount);
    }

    uint256[49] private __gap;
}
