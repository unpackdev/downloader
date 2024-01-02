// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ResolverCache.sol";
import "./OpenFundMarket.sol";
import "./OFMConstants.sol";
import "./INavOracle.sol";

contract NavOracle is INavOracle, AdminControl, ResolverCache {

	struct PoolNavInfo {
		mapping(uint256 => uint256) navs;
		uint256 latestSetNavTime;
		uint256 allTimeHighRedeemNav;
	}

	mapping(bytes32 => PoolNavInfo) public poolNavInfos;

	modifier onlyMarket {
		require(msg.sender == _openFundMarket());
		_;
	}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
	function initialize(address resolver_) external initializer {
		__AdminControl_init_unchained(_msgSender());
		__ResolverCache_init(resolver_);
	}

	function setSubscribeNavOnlyMarket(bytes32 poolId_, uint256 time_, uint256 nav_) 
		external virtual override onlyMarket 
	{
		require(time_ <= block.timestamp, "NavOracle: invalid time");
		uint256 dayTime = time_ / 86400 * 86400;
		poolNavInfos[poolId_].navs[dayTime] = nav_;
		if (dayTime > poolNavInfos[poolId_].latestSetNavTime) {
			poolNavInfos[poolId_].latestSetNavTime = dayTime;
		}
		emit SetSubscribeNav(poolId_, dayTime, nav_);
	}

	function updateAllTimeHighRedeemNavOnlyMarket(bytes32 poolId_, uint256 nav_) 
		external virtual override onlyMarket
	{
		uint256 previousNav = poolNavInfos[poolId_].allTimeHighRedeemNav;
		if (nav_ > previousNav) {
			poolNavInfos[poolId_].allTimeHighRedeemNav = nav_;
			emit UpdateAllTimeHighRedeemNav(poolId_, previousNav, nav_);
		}
	}

	function getSubscribeNav(bytes32 poolId_, uint256 time_) 
		external view virtual override returns (uint256 nav_, uint256 navTime_) 
	{
		PoolNavInfo storage poolNavInfo = poolNavInfos[poolId_];
		navTime_ = time_ / 86400 * 86400;
		nav_ = poolNavInfo.navs[navTime_];

		// if nav of the day is not set, return the latest nav info
		if (nav_ == 0) {
			navTime_ = poolNavInfo.latestSetNavTime;
			nav_ = poolNavInfo.navs[navTime_];
		}
	}

	function getAllTimeHighRedeemNav(bytes32 poolId_) 
		external view virtual override returns (uint256) 
	{
		return poolNavInfos[poolId_].allTimeHighRedeemNav;
	}

	function _openFundMarket() internal view returns (address) {
		return getRequiredAddress(OFMConstants.CONTRACT_OFM, "NavOracle: OFM not set");
	}

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory) {
		bytes32[] memory existAddresses = super._resolverAddressesRequired();
		bytes32[] memory newAddresses = new bytes32[](1);
		newAddresses[0] = OFMConstants.CONTRACT_OFM;
		return _combineArrays(existAddresses, newAddresses);
	}	
}