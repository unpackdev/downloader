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

	uint256 private constant _USE_EXCHANGE_BALANCE = 1 << 255;
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

	error EthDepositRejected();
	error InsufficientReturnAmount();
	error InsufficientBalance();

	function fillThroughPools(
		address senderAddress,
		IAggregationExecutor executor,
		LibValidator.SwapDescription memory desc,
		bytes calldata data
	) external {
		(uint256 returnAmount, uint256 spentAmount, ) = swap(senderAddress, executor, desc, data);

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
		bytes calldata data
	) public returns (uint256 returnAmount, uint256 spentAmount, uint256 gasLeft) {
		(uint112 amount, uint112 minReturnAmount) = (
			LibUnitConverter.decimalToBaseUnit(address(desc.srcToken), desc.amount),
			LibUnitConverter.decimalToBaseUnit(address(desc.dstToken), desc.minReturnAmount)
		);
		address payable dstReceiver = (desc.dstReceiver == address(0)) ? payable(sender) : desc.dstReceiver;

		returnAmount = desc.dstToken.uniBalanceOf(dstReceiver);
		_execute(sender, executor, data);
		returnAmount = desc.dstToken.uniBalanceOf(dstReceiver) - returnAmount;

		if (returnAmount < minReturnAmount) revert InsufficientReturnAmount();

		gasLeft = gasleft();
		spentAmount = amount;

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

	function transferToInitialSource(
		address sender,
		LibValidator.SwapDescription memory desc,
		bytes calldata permit,
		mapping(address => mapping(address => int192)) storage assetBalances,
		mapping(address => MarginalFunctionality.Liability[]) storage liabilities
	) external {
		bool srcETH = SafeTransferHelper.isETH(desc.srcToken);
		bool useExchangeBalance = desc.flags & _USE_EXCHANGE_BALANCE != 0;
		uint112 amount = LibUnitConverter.decimalToBaseUnit(address(desc.srcToken), desc.amount);

		if (!srcETH) {
			if (permit.length > 0) {
				desc.srcToken.safePermit(permit);
			}
		}

		if (useExchangeBalance) {
			if ((srcETH && (msg.value >= amount)) || (!srcETH && (msg.value != 0))) revert Errors.InvalidMsgValue();

			int updateAmount = -int(desc.amount);
			if (srcETH) {
				uint112 valueInDecimal = LibUnitConverter.baseUnitToDecimal(address(0), msg.value);
				updateAmount += int(uint(valueInDecimal));
			}
			LibExchange._updateBalance(sender, address(desc.srcToken), updateAmount, assetBalances, liabilities);
			if (assetBalances[msg.sender][address(desc.srcToken)] < 0) revert InsufficientBalance();

			desc.srcToken.safeTransfer(desc.srcReceiver, amount);
		} else {
			if (msg.value != (srcETH ? amount : 0)) revert Errors.InvalidMsgValue();

			if (!srcETH) {
				desc.srcToken.safeTransferFrom(sender, desc.srcReceiver, amount);
			}
		}
	}

	function _execute(address srcTokenOwner, IAggregationExecutor executor, bytes calldata data) private {
		bytes4 callBytesSelector = executor.callBytes.selector;
		assembly {
			// solhint-disable-line no-inline-assembly
			let ptr := mload(0x40)
			mstore(ptr, callBytesSelector)
			mstore(add(ptr, 0x04), srcTokenOwner)
			calldatacopy(add(ptr, 0x24), data.offset, data.length)

			if iszero(call(gas(), executor, callvalue(), ptr, add(0x24, data.length), 0, 0)) {
				returndatacopy(ptr, 0, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}
}
