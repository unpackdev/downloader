// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./GovernorControl.sol";
import "./IOpenFundMarketStorage.sol";

contract OpenFundMarketStorage is IOpenFundMarketStorage, GovernorControl {
	// keccak256(openFundSFT, openFundSlot)
	mapping(bytes32 => PoolInfo) public poolInfos;

	// keccak256(openFundSFT, openFundSlot) => buyer => purchased amount
	mapping(bytes32 => mapping(address => uint256)) public purchasedRecords;

	// redeemSlot => close time
	mapping(uint256 => uint256) public poolRedeemSlotCloseTime;

	// redeemSlot => openFundTokenId
	mapping(uint256 => uint256) internal _poolRedeemTokenId;

	mapping(address => bool) public currencies;

	mapping(address => SFTInfo) public sftInfos;

	uint256 public protocolFeeRate;
	address public protocolFeeCollector;

	mapping(bytes32 => uint256) public previousRedeemSlot;

	uint256[42] private __gap;
}	