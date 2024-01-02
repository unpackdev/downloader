// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISFTIssuableDelegate {
    function createSlotOnlyIssueMarket(address txSender, bytes calldata inputSlotInfo) external returns(uint256 slot);
	function mintOnlyIssueMarket(address txSender, address currency, address mintTo, uint256 slot, uint256 value) external payable returns(uint256 tokenId);
}
