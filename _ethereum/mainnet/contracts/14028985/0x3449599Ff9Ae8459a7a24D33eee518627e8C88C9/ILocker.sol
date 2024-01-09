// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ILocker {
	function createLock(uint256, uint256) external;

	function increaseAmount(uint256) external;

	function increaseUnlockTime(uint256) external;

	function release() external;

	function claimFXSRewards(address) external;

	function execute(
		address,
		uint256,
		bytes calldata
	) external returns (bool, bytes memory);

	function setGovernance(address) external;

	function vote(
		uint256,
		address,
		bool
	) external;

	function voteGaugeWeight(address, uint256) external;
}
