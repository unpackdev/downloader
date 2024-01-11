// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./CountersUpgradeable.sol";

struct Snapshots {
	uint256[] ids;
	uint256[] values;
}

contract SnapshotStorageV1 {
	using CountersUpgradeable for CountersUpgradeable.Counter;

	mapping(address => Snapshots) private _accountBalanceSnapshots;
	Snapshots private _totalSupplySnapshots;
	CountersUpgradeable.Counter private _currentSnapshotId;
	uint256[46] private __gap;
}

contract EIP712StorageV1 {
	using CountersUpgradeable for CountersUpgradeable.Counter;

	bytes32 private _HASHED_NAME;
	bytes32 private _HASHED_VERSION;
	bytes32 private constant _TYPE_HASH =
		keccak256(
			"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
		);
	uint256[50] private __gap;
}

contract ERC20PermitStorageV1 {
	using CountersUpgradeable for CountersUpgradeable.Counter;

	mapping(address => CountersUpgradeable.Counter) private _nonces;
	bytes32 private _PERMIT_TYPEHASH;
	uint256[49] private __gap;
}

struct Checkpoint {
	uint32 fromBlock;
	uint224 votes;
}

contract ERC20VotesStorageV1 {
	mapping(address => address) private _delegates;
	mapping(address => Checkpoint[]) private _checkpoints;
	Checkpoint[] private _totalSupplyCheckpoints;
	uint256[47] private __gap;
}