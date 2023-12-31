// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IRouterClient.sol";

import "./Client.sol";

import "./SafeERC20.sol";

contract CCIPBridgeProxy {
	using SafeERC20 for IERC20;

	/**
	 * Errors
	 */

	error InvalidValue();
	error FeeRefundFail();
	error InvalidFeeToken();
	error InvalidToken();
	error InvalidData();
	error InvalidExtraArgs();
	error InvalidGasLimit();

	/**
	 * Constants
	 */

	IRouterClient internal immutable _router;
	IERC20 internal immutable _token;

	/**
	 * Constructor
	 */

	constructor(IRouterClient router, IERC20 token) {
		_router = router;
		_token = token;
		token.approve(address(router), type(uint256).max);
	}

	/**
	 * Non-View Functions
	 */

	function ccipSend(
		uint64 destinationChainSelector,
		Client.EVM2AnyMessage calldata message
	) external payable returns (bytes32 messageId) {
		_validateMessage(message);

		uint256 fee = _router.getFee(destinationChainSelector, message);
		if (fee > msg.value) revert InvalidValue();

		if (fee < msg.value) {
			(bool success, ) = msg.sender.call{value: fee}("");
			if (success == false) revert FeeRefundFail();
		}

		SafeERC20.safeTransferFrom(_token, msg.sender, address(this), message.tokenAmounts[0].amount);

		messageId = _router.ccipSend{value: fee}(destinationChainSelector, message);
	}

	/**
	 * View Functions
	 */

	function getFee(uint64 destinationChainSelector, Client.EVM2AnyMessage calldata message) external view returns (uint256 fee) {
		_validateMessage(message);
		return _router.getFee(destinationChainSelector, message);
	}

	function getRouter() external view returns (address) {
		return address(_router);
	}

	function getToken() external view returns (address) {
		return address(_token);
	}

	/**
	 * Internal functions
	 */

	function _validateMessage(Client.EVM2AnyMessage calldata message) internal view {
		if (message.feeToken != address(0)) revert InvalidFeeToken();

		if (message.tokenAmounts.length != 1 || message.tokenAmounts[0].token != address(_token)) revert InvalidToken();
		if (message.data.length > 0) revert InvalidData();

		if (message.extraArgs.length < 4 || bytes4(message.extraArgs) != Client.EVM_EXTRA_ARGS_V1_TAG) {
			revert InvalidExtraArgs();
		}

		if (abi.decode(message.extraArgs[4:], (Client.EVMExtraArgsV1)).gasLimit != 0) revert InvalidGasLimit();
	}
}
