// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

/* solhint-disable reason-string */

import "./BasePaymaster.sol";
import "./HashLib.sol";

/**
 * @title Estimation paymaster Contract
 * @author fun.xyz
 * @notice A contract that extends the BasePaymaster contract. This allows sponsors to estimate the gas of useroperations without a prefund.
 */
contract EstimationPaymaster is BasePaymaster {
	using UserOperationLib for UserOperation;

	mapping(address => uint256) public balances;

	constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

	receive() external payable {
		addDepositTo(msg.sender);
	}

	/**
	 * @notice Adds the specified deposit amount to the deposit balance of the given sponsor address.
	 * @param sponsor The address of the sponsor whose deposit balance will be increased.
	 * @dev msg.value: The amount of the deposit to be added.
	 * @dev Deposits were added so that fun.xyz doesn't control the ability to get estimates.
	 */
	function addDepositTo(address sponsor) public payable {
		balances[sponsor] += msg.value;
		entryPoint.depositTo{value: msg.value}(address(this));
	}

	/**
	 * @notice Withdraws the specified deposit amount from the deposit balance of the calling sender and transfers it to the target address.
	 * @param target The address to which the deposit amount will be transferred.
	 * @param amount The amount of the deposit to be withdrawn and transferred.
	 */
	function withdrawDepositTo(uint256 amount, address payable target) external {
		require(balances[msg.sender] >= amount, "Insufficient balance");
		balances[msg.sender] -= amount;
		entryPoint.withdrawTo(target, amount);
	}

	/**
	 * @notice Bypasses paymaster step in validation so additional gas isn't added. 
	 	We must return context information so the postop can be executed. 
		Return signature failed so estimation works.
	 */
	function _validatePaymasterUserOp(
		UserOperation calldata,
		bytes32,
		uint256
	) internal view override returns (bytes memory context, uint256 sigTimeRange) {
		return ("fun.xyz", 1);
	}

	/**
	 * @notice Always revert so the gas estimation passes but execution is stopped.
	 */
	function _postOp(PostOpMode, bytes calldata, uint256) internal override {
		return;
	}
}
