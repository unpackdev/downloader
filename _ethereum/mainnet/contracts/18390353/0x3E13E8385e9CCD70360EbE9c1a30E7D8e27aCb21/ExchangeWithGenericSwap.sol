// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./ExchangeWithAtomic.sol";
import "./LibGenericSwap.sol";
import "./IAggregationExecutor.sol";

contract ExchangeWithGenericSwap is ExchangeWithAtomic {
	using SafeERC20 for IERC20;
	using SafeTransferHelper for IERC20;

	error InsufficientBalance();

	/// @notice Fills user's limit orders through pools, delegating all calls encoded in `data` to `executor`. See tests for usage examples
	/// @param order User signed limit order
	/// @param executor Aggregation executor that executes calls described in `data`
	/// @param desc Swap description
	/// @param data Encoded calls that `caller` should execute in between of swaps
	function fillThroughPools(
		uint112 filledAmount,
		LibValidator.Order calldata order,
		IAggregationExecutor executor,
		LibValidator.SwapDescription memory desc,
		bytes calldata permit,
		bytes calldata data
	) external nonReentrant{
		LibValidator.checkOrderSingleMatch(order, desc, filledAmount, block.timestamp);
		updateFilledAmount(order, filledAmount);
		LibGenericSwap.fillThroughPools(order.senderAddress, executor, desc, permit, data, WETH);
		payMatcherFee(order);
	}

	/// @notice Performs a swap, delegating all calls encoded in `data` to `executor`. See tests for usage examples
	/// @param executor Aggregation executor that executes calls described in `data`
	/// @param desc Swap description
	/// @param data Encoded calls that `caller` should execute in between of swaps
	/// @return returnAmount Resulting token amount
	/// @return spentAmount Source token amount
	/// @return gasLeft Gas left
	function swap(
		IAggregationExecutor executor,
		LibValidator.SwapDescription memory desc,
		bytes calldata permit,
		bytes calldata data
	) public payable returns (uint256 returnAmount, uint256 spentAmount, uint256 gasLeft) {
		return _swap(msg.sender, executor, desc, permit, data);
	}

	function _swap(
		address sender,
		IAggregationExecutor executor,
		LibValidator.SwapDescription memory desc,
		bytes calldata permit,
		bytes calldata data
	) internal nonReentrant returns (uint256 returnAmount, uint256 spentAmount, uint256 gasLeft) {
		(returnAmount, spentAmount, gasLeft) = LibGenericSwap.swap(sender, executor, desc, permit, data, WETH);
	}

	function payMatcherFee(LibValidator.Order memory order) internal {
		LibExchange._updateBalance(
			order.senderAddress,
			order.matcherFeeAsset,
			-int(uint(order.matcherFee)),
			assetBalances,
			liabilities
		);
		if (assetBalances[order.senderAddress][order.matcherFeeAsset] < 0) revert InsufficientBalance();
		LibExchange._updateBalance(
			order.matcherAddress,
			order.matcherFeeAsset,
			int(uint(order.matcherFee)),
			assetBalances,
			liabilities
		);
	}
}
