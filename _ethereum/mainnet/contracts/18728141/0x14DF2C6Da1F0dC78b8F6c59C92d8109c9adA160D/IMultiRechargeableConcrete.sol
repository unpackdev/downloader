// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultiRechargeableConcrete {
	struct SlotRechargeInfo {
		uint256 totalValue;      // accumulated minted value
		uint256 rechargedAmount; // accumulated recharged currency amount
	}

	struct TokenClaimInfo {
		uint256 claimedAmount;   // accumulated claimed currency amount
	}

	function rechargeOnlyDelegate(uint256 slot_, address currency_, uint256 rechargeAmount_) external payable;
	function mintOnlyDelegate(uint256 tokenId_, uint256 slot_, uint256 value_) external;
	function claimOnlyDelegate(uint256 tokenId_, address currency_, uint256 amount_) external;
	function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromBalance_, uint256 value_) external;
	
	function totalValue(uint256 slot_) external view returns (uint256);
	function rechargedAmount(uint256 slot_) external view returns (uint256);
	function claimedAmount(uint256 tokenId_) external view returns(uint256);
	function claimableAmount(uint256 tokenId_) external view returns (uint256);
}