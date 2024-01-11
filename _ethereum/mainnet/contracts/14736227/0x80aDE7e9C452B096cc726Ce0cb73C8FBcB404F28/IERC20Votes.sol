// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

interface IERC20Votes is IERC20Upgradeable {
	struct Snapshot {
		uint32 fromBlock;
		uint224 votes;
	}

	enum DelegationType {
		VOTING_POWER,
		PROPOSITION_POWER
	}

	event DelegateChanged(
		address indexed delegator,
		address indexed fromDelegate,
		address indexed toDelegate,
		DelegationType delegationType
	);

	event DelegatePowerChanged(
		address indexed delegate,
		uint256 previousBalance,
		uint256 newBalance,
		DelegationType delegationType
	);

	function propositionSnapshots(address account, uint32 pos)
		external
		view
		returns (Snapshot memory);

	function votingSnapshots(address account, uint32 pos)
		external
		view
		returns (Snapshot memory);

	function numPropositionSnapshots(address account)
		external
		view
		returns (uint32);

	function numVotingSnapshots(address account) external view returns (uint32);

	function propositionDelegates(address owner)
		external
		view
		returns (address);

	function votingDelegates(address owner) external view returns (address);

	function propositionPower(address account) external view returns (uint256);

	function votingPower(address account) external view returns (uint256);

	function balanceOfAt(address account, uint256 blockNumber)
		external
		view
		returns (uint256);

	function totalSupplyAt(uint256 blockNumber) external view returns (uint256);

	function propositionPowerAt(address account, uint256 blockNumber)
		external
		view
		returns (uint256);

	function votingPowerAt(address account, uint256 blockNumber)
		external
		view
		returns (uint256);

	function delegate(address delegatee) external;

	function delegatePropositionPower(address delegatee) external;

	function delegateVotingPower(address delegatee) external;

	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function delegateProposalBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function delegateVoteBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}
