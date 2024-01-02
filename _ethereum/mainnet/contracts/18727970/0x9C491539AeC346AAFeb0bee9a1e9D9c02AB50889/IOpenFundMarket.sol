// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IOpenFundMarketStorage.sol";

interface IOpenFundMarket is IOpenFundMarketStorage {

	event SetCurrency(address indexed currency, bool enabled);
	event AddSFT(address indexed sft, address manager);
	event RemoveSFT(address indexed sft);
	event SetProtocolFeeRate(uint256 oldFeeRate, uint256 newFeeRate);
	event SetProtocolFeeCollector(address oldFeeCollector, address newFeeCollector);

	event CreatePool(bytes32 indexed poolId, address indexed currency, address indexed sft, PoolInfo poolInfo_);
	event RemovePool(bytes32 indexed poolId);
	event UpdateFundraisingEndTime(bytes32 indexed poolId, uint64 oldEndTime, uint64 newEndTime);

	event Subscribe(bytes32 indexed poolId, address indexed buyer, uint256 tokenId, uint256 value, address currency, uint256 nav, uint256 payment);
	event RequestRedeem(bytes32 indexed poolId, address indexed owner, uint256 indexed openFundShareId, uint256 openFundRedemptionId, uint256 redeemValue);
	event RevokeRedeem(bytes32 indexed poolId, address indexed owner, uint256 indexed openFundRedemptionId, uint256 openFundShareId);

	event CloseRedeemSlot(bytes32 indexed poolId, uint256 previousRedeemSlot, uint256 newRedeemSlot);
	event SetSubscribeNav(bytes32 indexed poolId, uint256 indexed time, uint256 nav);
    event SetRedeemNav(bytes32 indexed poolId, uint256 indexed redeemSlot, uint256 nav);

	event SettleCarry(bytes32 indexed poolId, uint256 indexed redeemSlot, address currency, uint256 currencyBalance, uint256 carryAmount);
	event SettleProtocolFee(bytes32 indexed poolId, address currency, uint256 protocolFeeAmount);

    event UpdatePoolInfo(bytes32 indexed poolId, uint16 newCarryRate, address newCarryCollector, uint256 newSubscribeMin, uint256 newSubscribeMax, address newSubscribeNavManager, address newRedeemNavManager);

	struct InputPoolInfo {
		address openFundShare;
        address openFundRedemption;
		address currency;
		uint16 carryRate;
		address vault;
		uint64 valueDate;
		address carryCollector;
		address subscribeNavManager;
        address redeemNavManager;
		address navOracle;
		uint64 createTime;
		address[] whiteList;
		SubscribeLimitInfo subscribeLimitInfo;
	}

    function createPool(InputPoolInfo calldata inputPoolInfo_) external returns (bytes32 poolId_);
	
	function subscribe(bytes32 poolId_, uint256 currentAmount_, uint256 openFundShareId_, uint64 expireTime_) external returns (uint256 value_);

	function requestRedeem(bytes32 poolId_, uint256 openFundShareId_, uint256 openFundRedemptionId_, uint256 value_) external;
	function revokeRedeem(bytes32 poolId_, uint256 openFundRedemptionId_) external;

	function closeCurrentRedeemSlot(bytes32 poolId_) external;
    function setSubscribeNav(bytes32 poolId_, uint256 time_, uint256 nav_) external;
	function setRedeemNav(bytes32 poolId_, uint256 redeemSlot_, uint256 nav_, uint256 currencyBalance_) external;
}
