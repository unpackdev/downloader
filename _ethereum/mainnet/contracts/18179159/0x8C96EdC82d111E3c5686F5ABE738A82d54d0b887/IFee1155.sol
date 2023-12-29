// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IFee1155 {
	function setApprovalForAll ( address, bool ) external;
	function safeTransferFrom (
		address, address, uint256, uint256, bytes memory) external;
}