// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenFundRedemptionConcrete {
	
	struct RedeemInfo {
		bytes32 poolId;
		address currency;
		uint256 createTime;
		uint256 nav;
	}	

	function setRedeemNavOnlyDelegate(uint256 slot_, uint256 nav_) external;

	function getRedeemInfo(uint256 slot_) external view returns (RedeemInfo memory);
	function getRedeemNav(uint256 slot_) external view returns (uint256);
}