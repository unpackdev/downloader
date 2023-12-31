//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC5192.sol";

interface ILockableV3 is IERC5192 {
	// ====================================================
	// EVENTS
	// ====================================================
	event LockingEnabledToggle(bool);
	event OverrideLockToggle(bool);

	// ====================================================
	// Errors
	// ====================================================
	error OperationBlockedByOverride();
	error OperationBlockedByTokenLock();
	error TokenLockingDisabled();

	// ====================================================
	// ENUMS, STRUCT, etc
	// ====================================================
	struct LockInfo {
		uint256 lockTime;
		uint256 lockDuration;
	}

	/**
    @notice retrieve TokenLockingEnabled state
     */
	function getTokenLockingEnabled() external returns (bool);

	/**
    @notice retrieves a token's locked state
     */
	function getTokenLockedState(uint256 tokenId) external returns (bool lockedState, LockInfo memory lockInfo);

	/**
    @notice explicit enabling of token locking
     */
	function enableTokenLocking() external;

	/**
    @notice explicit disabling of token locking
     */
	function disableTokenLocking() external;
}
