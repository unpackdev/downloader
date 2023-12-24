// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./EscapeHatch.sol";

import "./ISuperVerseStaker.sol";

/**
	Thrown when attempting to set item values with unequal argument arrays lengths.
*/
error CantConfigureItemValues ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title SuperVerseDAO staking contract.
	@author throw; <@0xthrpw>
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	This contract provides methods for configuring the SuperVerseDAO staking 
	contract

	@custom:date May 15th, 2023.
*/
contract StakerConfig is EscapeHatch {

	/// The identifier for the right to configure emission rates and the DAO tax.
	bytes32 constant private  _CONFIG_ITEM_VALUES = 
		keccak256("CONFIG_ITEM_VALUES");

	/// The identifier for the right to configure the length of reward emission.
	bytes32 constant private  _CONFIG_WINDOW = 
		keccak256("CONFIG_WINDOW");

	/// The address of the Elliotrades NFT collection
	address immutable public ET_COLLECTION;

	/// The address of the SuperFarm NFT collection
	address immutable public SF_COLLECTION;

	/// The address of the ERC20 staking token
	address immutable public TOKEN;

	/// The amount of time for which rewards are emitted
	uint256 public immutable REWARD_PERIOD;

	/// The timestamp of when rebase can next be called
	uint256 public nextRebaseTimestamp;

	/// The minimum amount of seconds between rebase calls
	uint256 public rebaseCooldown;

	/// collection type > group id > equivalent token amount
	mapping( ItemOrigin => mapping ( uint256 => uint128 ) ) public itemValues;

	/// user address > timestamp of last stake operation
	mapping ( address => uint256 ) public stakeTimestamps;

	/**
	   Construct a new instance of a SuperVerse staking configuration with the 
	   following parameters.

	   @param _etCollection The address of the Elliotrades NFT collection
	   @param _sfCollection The address of the SuperFarm NFT collection
	   @param _token The address of the staking erc20 token
	   @param _rewardPeriod The length of time rewards are emitted
	*/
	constructor(
		address _etCollection,
		address _sfCollection,
		address _token,
		uint256 _rewardPeriod
	) EscapeHatch (
		msg.sender
	) {
		ET_COLLECTION = _etCollection;
		SF_COLLECTION = _sfCollection;
		TOKEN = _token;
		REWARD_PERIOD = _rewardPeriod;
		rebaseCooldown = 1 weeks;
	}


	/**
		This function allows a permitted user to configure the equivalent token
		values available for each item rarity/type.

		@param _assetType The type of asset whose timelock options are being 
			configured.
		@param _groupIds An array with IDs for specific rewards 
			available under `_assetType`.
		@param _values An array keyed to `_groupIds` containing the token 
			value for the group id
	*/
	function configureItemValues (
		ItemOrigin _assetType,
		uint256[] memory _groupIds,
		uint128[] memory _values
	) external hasValidPermit(_UNIVERSAL, _CONFIG_ITEM_VALUES) {
		if (_groupIds.length != _values.length) {
			revert CantConfigureItemValues();
		}
		for (uint256 i; i < _groupIds.length; ) {
			itemValues[_assetType][_groupIds[i]] = _values[i];
			unchecked { ++i; }
		}
	}

	/**
	   
	*/
	function setRebaseCooldown (
		uint256 _rebaseCooldown
	) external hasValidPermit(_UNIVERSAL, _CONFIG_WINDOW) {
		rebaseCooldown = _rebaseCooldown;
	}
}