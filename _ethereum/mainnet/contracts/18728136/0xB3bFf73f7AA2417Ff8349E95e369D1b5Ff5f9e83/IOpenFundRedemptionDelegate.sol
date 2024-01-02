// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenFundRedemptionDelegate {
	function setRedeemNavOnlyMarket(uint256 slot_, uint256 nav_) external;
}