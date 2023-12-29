// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

/* solhint-disable reason-string */


import "./Ownable2StepNoRenounce.sol";
import "./IPaymaster.sol";
import "./IEntryPoint.sol";

/**
 * @title BasePaymaster
 * @author fun.xyz eth-infinitism
 * @notice Helper class for creating a paymaster.
 * provides helper methods for staking.
 * validates that the postOp is called only by the entryPoint
 */
abstract contract BasePaymaster is IPaymaster, Ownable2StepNoRenounce {
	IEntryPoint public immutable entryPoint;

	constructor(IEntryPoint _entryPoint) {
		require(address(_entryPoint) != address(0), "FW300");
		entryPoint = _entryPoint;
		emit PaymasterCreated(_entryPoint);
	}

	/**
	 * payment validation: check if paymaster agrees to pay.
	 * Must verify sender is the entryPoint.
	 * Revert to reject this request.
	 * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted)
	 * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
	 * @param userOp the user operation
	 * @param userOpHash hash of the user's request data.
	 * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
	 * @return context value to send to a postOp
	 *      zero length to signify postOp is not required.
	 * @return sigTimeRange Note: we do not currently support validUntil and validAfter
	 */
	function validatePaymasterUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 maxCost
	) external override returns (bytes memory context, uint256 sigTimeRange) {
		_requireFromEntryPoint();
		return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
	}

	/**
	 * payment validation: check if paymaster agrees to pay.
	 * Must verify sender is the entryPoint.
	 * Revert to reject this request.
	 * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted)
	 * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
	 * @param userOp the user operation
	 * @param userOpHash hash of the user's request data.
	 * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
	 * @return context value to send to a postOp
	 *      zero length to signify postOp is not required.
	 * @return sigTimeRange Note: we do not currently support validUntil and validAfter
	 */
	function _validatePaymasterUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 maxCost
	) internal virtual returns (bytes memory context, uint256 sigTimeRange);

	/**
	 * post-operation handler.
	 * Must verify sender is the entryPoint
	 * @param mode enum with the following options:
	 *      opSucceeded - user operation succeeded.
	 *      opReverted  - user op reverted. still has to pay for gas.
	 *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
	 *                       Now this is the 2nd call, after user's op was deliberately reverted.
	 * @param context - the context value returned by validatePaymasterUserOp
	 * @param actualGasCost - actual gas used so far (without this postOp call).
	 */
	function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external override {
		_requireFromEntryPoint();
		_postOp(mode, context, actualGasCost);
	}

	/**
	 * post-operation handler.
	 * (verified to be called only through the entryPoint)
	 * @dev if subclass returns a non-empty context from validatePaymasterUserOp, it must also implement this method.
	 * @param mode enum with the following options:
	 *      opSucceeded - user operation succeeded.
	 *      opReverted  - user op reverted. still has to pay for gas.
	 *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
	 *                       Now this is the 2nd call, after user's op was deliberately reverted.
	 * @param context - the context value returned by validatePaymasterUserOp
	 * @param actualGasCost - actual gas used so far (without this postOp call).
	 */
	function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal virtual {
		(mode, context, actualGasCost); // unused params
		// subclass must override this method if validatePaymasterUserOp returns a context
		revert("must override");
	}

	/**
	 * add stake for this paymaster.
	 * This method can also carry eth value to add to the current stake.
	 * @param unstakeDelaySec - the unstake delay for this paymaster. Can only be increased.
	 */
	function addStakeToEntryPoint(uint32 unstakeDelaySec) external payable onlyOwner {
		entryPoint.addStake{value: msg.value}(unstakeDelaySec);
	}

	/**
	 * unlock the stake, in order to withdraw it.
	 * The paymaster can't serve requests once unlocked, until it calls addStake again
	 */
	function unlockStakeFromEntryPoint() external onlyOwner {
		entryPoint.unlockStake();
	}

	/**
	 * withdraw the entire paymaster's stake.
	 * stake must be unlocked first (and then wait for the unstakeDelay to be over)
	 * @param withdrawAddress the address to send withdrawn value.
	 */
	function withdrawStakeFromEntryPoint(address payable withdrawAddress) external onlyOwner {
		require(withdrawAddress != address(0), "FW351");
		entryPoint.withdrawStake(withdrawAddress);
	}

	/// validate the call is made from a valid entrypoint
	function _requireFromEntryPoint() internal virtual {
		require(msg.sender == address(entryPoint), "FW301");
	}

	event PaymasterCreated(IEntryPoint entryPoint);
}
