// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./AccessControl.sol";

/// @title A simple on-chain price oracle mechanism
/// @author github.com/drbh
/// @notice Offchain clients can update the prices in this contract. The public can read prices
contract NFTFloorOracle is AccessControl {
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

	struct OracleConfig {
		uint128 twapPeriod;
	}

	struct PriceInformation {
		/// @dev last reported floor price
		uint128 twap;
		uint64 lastUpdateTime;
	}

	/// @dev address of the NFT contract -> price information
	mapping (address => PriceInformation) priceMap;

	/// @dev storage for oracle configurations
	OracleConfig config;

	/// @notice Allow contract creator to set admin and first updater
	/// @param admin The admin who can change roles
	/// @param updaters The inital updaters
	constructor(address admin, address[] memory updaters) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

		for (uint i=0; i < updaters.length; i++) {
			_setupRole(UPDATER_ROLE, updaters[i]);
		}
	}

	/// @notice Allows owner to set new price on PriceInformation and updates the
	/// internal TWAP cumulativePrice.
	/// @param token The nft contracts to set a floor price for
	/// @param twap The last floor twap
	function setPrice(address token, uint128 twap) onlyRole(UPDATER_ROLE) public {
		/// @dev get storage ref for gas savings
		PriceInformation storage priceMapEntry = priceMap[token];

		/// @dev set values
		priceMapEntry.twap = twap;
		priceMapEntry.lastUpdateTime = uint64(block.timestamp);
	}

	/// @notice Allows owner to set new price on PriceInformation and updates the
	/// internal TWAP cumulativePrice.
	/// @param tokens The nft contract to set a floor price for
	function setMultiplePrices(address[] calldata tokens, uint128[] calldata twaps) onlyRole(UPDATER_ROLE) public {
		require(tokens.length == twaps.length, "Tokens and price length differ");
		for(uint i; i<tokens.length; i++) {
			setPrice(tokens[i], twaps[i]);
		}
	}

	/// @notice Allows owner to update oracle configs
	/// @param twapPeriod The period of the time weighted average price
	function setConfig(uint128 twapPeriod) onlyRole(UPDATER_ROLE) public {
		config.twapPeriod = twapPeriod;
	}

	/// @param token The nft contract
	/// @return twap The most recent twap on chain
	function getTwap(address token) view public returns(uint128 twap) {
		return priceMap[token].twap;
	}

	/// @param token The nft contract
	/// @return timestamp The timestamp of the last update for an asset
	function getLastUpdateTime(address token) view public returns(uint128 timestamp) {
		return priceMap[token].lastUpdateTime;
	}
}
