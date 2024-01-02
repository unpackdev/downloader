// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";

import "./IAsyncSwapper.sol";
import "./Error.sol";
import "./ERC20Utils.sol";

contract AsyncSwapper is IAsyncSwapper {
    address public immutable aggregator;

    constructor(address _aggregator) {
        if (_aggregator == address(0)) revert Error.ZeroAddress();
        aggregator = _aggregator;
    }

    /// @inheritdoc IAsyncSwapper
    function swap(SwapParams memory swapParams) public payable virtual returns (uint256 buyTokenAmountReceived) {
        if (swapParams.buyTokenAddress == address(0)) revert Error.ZeroAddress();
        if (swapParams.sellTokenAddress == address(0)) revert Error.ZeroAddress();
        if (swapParams.sellAmount == 0) revert Error.ZeroAmount();
        if (swapParams.buyAmount == 0) revert Error.ZeroAmount();

        IERC20 sellToken = IERC20(swapParams.sellTokenAddress);
        IERC20 buyToken = IERC20(swapParams.buyTokenAddress);

        uint256 sellTokenBalance = sellToken.balanceOf(address(this));

        if (sellTokenBalance < swapParams.sellAmount) revert Error.InsufficientBalance();

        ERC20Utils._approve(sellToken, aggregator, swapParams.sellAmount);

        uint256 buyTokenBalanceBefore = buyToken.balanceOf(address(this));

        // we don't need the returned value, we calculate the buyTokenAmountReceived ourselves
        // slither-disable-start low-level-calls,unchecked-lowlevel
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = aggregator.call(swapParams.data);
        // slither-disable-end low-level-calls,unchecked-lowlevel

        if (!success) revert SwapFailed();

        uint256 buyTokenBalanceAfter = buyToken.balanceOf(address(this));
        buyTokenAmountReceived = buyTokenBalanceAfter - buyTokenBalanceBefore;

        if (buyTokenAmountReceived < swapParams.buyAmount) {
            revert InsufficientBuyAmountReceived(address(buyToken), buyTokenAmountReceived, swapParams.buyAmount);
        }

        // slither-disable-next-line reentrancy-events
        emit Swapped(
            swapParams.sellTokenAddress,
            swapParams.buyTokenAddress,
            swapParams.sellAmount,
            swapParams.buyAmount,
            buyTokenAmountReceived
        );

        return buyTokenAmountReceived;
    }
}
