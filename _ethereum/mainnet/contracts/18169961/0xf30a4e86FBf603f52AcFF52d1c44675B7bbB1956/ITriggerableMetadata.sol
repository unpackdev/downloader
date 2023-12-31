// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface ITriggerableMetadata {
	function triggerBatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId) external;
}
