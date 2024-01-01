// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./ECDSA.sol";
import "./IERC20.sol";
import "./LibValidator.sol";
import "./LibExchange.sol";
import "./IAggregationExecutor.sol";
import "./Errors.sol";

library LibGenericSwap {
	using SafeERC20 for IERC20;
	using SafeTransferHelper for IERC20;

	event OrionPoolSwap(
		address sender,
		address st,
		address rt,
		uint256 st_r,
		uint256 st_a,
		uint256 rt_r,
		uint256 rt_a,
		address f
	);

	error ZeroMinReturn();
	error ZeroReturnAmount();
	error EthDepositRejected();
	error InsufficientReturnAmount();
	error InsufficientBalance();

	function fillThroughPools(
		address senderAddress,
		IAggregationExecutor executor,
		LibValidator.SwapDescription memory desc,
		bytes calldata permit,
		bytes calldata data,
		address weth
	) external {
		(uint256 returnAmount, uint256 spentAmount, ) = swap(senderAddress, executor, desc, permit, data, weth);

		uint112 filledAmount = LibUnitConverter.baseUnitToDecimal(address(desc.srcToken), spentAmount);
		uint112 quoteAmount = LibUnitConverter.baseUnitToDecimal(address(desc.dstToken), returnAmount);
		uint64 filledPrice = uint64((quoteAmount * 1e8) / filledAmount);

		emit LibExchange.NewTrade(
			senderAddress,
			address(this),
			address(desc.srcToken),
			address(desc.dstToken),
			filledPrice,
			filledAmount,
			quoteAmount
		);
	}

	function swap(
		address sender,
		IAggregationExecutor executor,
		LibValidator.SwapDescription memory desc,
		bytes calldata permit,
		bytes calldata data,
		address weth
	) public returns (uint256 returnAmount, uint256 spentAmount, uint256 gasLeft) {
		if (desc.minReturnAmount == 0) revert ZeroMinReturn();

		(desc.amount, desc.minReturnAmount) = (
			LibUnitConverter.decimalToBaseUnit(address(desc.srcToken), desc.amount),
			LibUnitConverter.decimalToBaseUnit(address(desc.dstToken), desc.minReturnAmount)
		);
		bool srcETH = SafeTransferHelper.isETH(desc.srcToken);
		if (msg.value != (srcETH ? desc.amount : 0)) revert Errors.InvalidMsgValue();

		if (!srcETH) {
			if (permit.length > 0) {
				desc.srcToken.safePermit(permit);
			}
			desc.srcToken.safeTransferFrom(sender, desc.srcReceiver, desc.amount);
		} else {
			IWETH(weth).deposit{value: desc.amount}();
			assert(IWETH(weth).transfer(desc.srcReceiver, desc.amount));
		}
		if (SafeTransferHelper.isETH(desc.dstToken)) {
			returnAmount = IERC20(weth).uniBalanceOf(address(this));
		} else {
			returnAmount = desc.dstToken.uniBalanceOf(address(this));
		}
		_execute(sender, executor, data);
		spentAmount = desc.amount;
		if (SafeTransferHelper.isETH(desc.dstToken)) {
			returnAmount = IERC20(weth).uniBalanceOf(address(this)) - returnAmount;
		} else {
			returnAmount = desc.dstToken.uniBalanceOf(address(this)) - returnAmount;
		}
		if (returnAmount == 0) revert ZeroReturnAmount();
		unchecked {
			returnAmount--;
		}
		if (returnAmount < desc.minReturnAmount) revert InsufficientReturnAmount();

		address payable dstReceiver = (desc.dstReceiver == address(0)) ? payable(sender) : desc.dstReceiver;
		SafeTransferHelper.safeAutoTransferTo(weth, address(desc.dstToken), dstReceiver, returnAmount);

		gasLeft = gasleft();

		emit OrionPoolSwap(
			sender,
			address(desc.srcToken),
			address(desc.dstToken),
			spentAmount,
			spentAmount,
			returnAmount,
			returnAmount,
			address(0xA6E4Ce17474d790fb25E779F9317c55963D2cbdf)
		);
	}

	function _execute(address srcTokenOwner, IAggregationExecutor executor, bytes calldata data) private {
		bytes4 callBytesSelector = executor.callBytes.selector;
		assembly {
			// solhint-disable-line no-inline-assembly
			let ptr := mload(0x40)
			mstore(ptr, callBytesSelector)
			mstore(add(ptr, 0x04), srcTokenOwner)
			calldatacopy(add(ptr, 0x24), data.offset, data.length)

			if iszero(call(gas(), executor, 0, ptr, add(0x24, data.length), 0, 0)) {
				returndatacopy(ptr, 0, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}
}
