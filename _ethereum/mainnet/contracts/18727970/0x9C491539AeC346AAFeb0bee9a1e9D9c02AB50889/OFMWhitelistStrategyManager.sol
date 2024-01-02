// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Constants.sol";
import "./AdminControl.sol";
import "./ResolverCache.sol";
import "./IOFMWhitelistStrategyManager.sol";
import "./OFMConstants.sol";
import "./OpenFundMarket.sol";

contract OFMWhitelistStrategyManager is IOFMWhitelistStrategyManager, AdminControl, ResolverCache {

	event SetWhitelist(bytes32 indexed poolId, bytes32 indexed whitelistId, bool permissionless);

	// whitelistId => whitelist mapping
	mapping(bytes32 => mapping(address => bool)) private _whitelists;

	// poolId => whitelistId list
	mapping(bytes32 => bytes32[]) internal _poolWhitelistIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
	function initialize(address resolver_) external initializer {
		__AdminControl_init_unchained(_msgSender());
		__ResolverCache_init(resolver_);
	}

	function setWhitelist(bytes32 poolId_, address[] calldata whitelist_) external virtual override {
		require(_msgSender() == _openFundMarket(), "WhitelistStrategyManager: only OFM");

		if (_poolWhitelistIds[poolId_].length == 0) {
			_poolWhitelistIds[poolId_].push(keccak256(abi.encode(poolId_, block.timestamp)));
		} else if (whitelist_.length == 0) {
			_poolWhitelistIds[poolId_][0] = keccak256(abi.encode(poolId_, block.timestamp));
		}

		bytes32 poolWhitelistId = _poolWhitelistIds[poolId_][0];
		for (uint256 i = 0; i < whitelist_.length; i++) {
			_whitelists[poolWhitelistId][whitelist_[i]] = true;
		}

		emit SetWhitelist(poolId_, poolWhitelistId, whitelist_.length == 0);
	}

	function isWhitelisted(bytes32 poolId_, address subscriber_) external view virtual override returns (bool) {
		bytes32[] storage poolWhitelistIds = _poolWhitelistIds[poolId_];
		if (poolWhitelistIds.length == 0) {
			return false;
		}

		bytes32 poolWhitelistId = poolWhitelistIds[0];
		return _whitelists[poolWhitelistId][subscriber_];
	}

	function getPoolWhitelistIds(bytes32 poolId_) external view virtual override returns (bytes32[] memory) {
		return _poolWhitelistIds[poolId_];
	}

	function _openFundMarket() internal view returns(address) {
		return getRequiredAddress(OFMConstants.CONTRACT_OFM, "WhitelistStrategyManager: OFM not set");
	}

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory) {
		bytes32[] memory existAddresses = super._resolverAddressesRequired();
		bytes32[] memory newAddresses = new bytes32[](1);
		newAddresses[0] = OFMConstants.CONTRACT_OFM;
		return _combineArrays(existAddresses, newAddresses);
	}
}