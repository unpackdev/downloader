// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOFMWhitelistStrategyManager {
	function setWhitelist(bytes32 poolId_, address[] calldata whitelist_) external;
	function isWhitelisted(bytes32 poolId_, address buyer_) external view returns (bool);
	function getPoolWhitelistIds(bytes32 poolId_) external view returns (bytes32[] memory);
}