//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Constants.sol";
import "./ResolverCache.sol";
import "./BaseSFTDelegateUpgradeable.sol";
import "./ISFTIssuableDelegate.sol";
import "./ISFTIssuableConcrete.sol";

abstract contract SFTIssuableDelegate is ISFTIssuableDelegate, BaseSFTDelegateUpgradeable, ResolverCache {
	function __SFTIssuableDelegate_init(address resolver_, string memory name_, string memory symbol_, uint8 decimals_, 
		address concrete_, address metadata_, address owner_) internal onlyInitializing {
			__BaseSFTDelegate_init(name_, symbol_, decimals_, concrete_, metadata_, owner_);
			__ResolverCache_init(resolver_);
	}

	function __SFTIssuableDelegate_init_unchained() internal onlyInitializing {
	}

	function createSlotOnlyIssueMarket(address txSender_, bytes calldata inputSlotInfo_) external virtual override nonReentrant returns(uint256 slot_) {
		require(_msgSender() == _issueMarket(), "SFTIssuableDelegate: only issue market");
		slot_ = ISFTIssuableConcrete(concrete()).createSlotOnlyDelegate(txSender_, inputSlotInfo_);
		require(!_slotExists(slot_), "SFTIssuableDelegate: slot already exists");
		ERC3525SlotEnumerableUpgradeable._createSlot(slot_);
		emit CreateSlot(slot_, txSender_, inputSlotInfo_);
	}

	function mintOnlyIssueMarket(address txSender_, address currency_, address mintTo_, uint256 slot_, uint256 value_) external payable virtual override nonReentrant returns(uint256 tokenId_) {
		require(_msgSender() == _issueMarket(), "SFTIssuableDelegate: only issue market");
		tokenId_ = ERC3525Upgradeable._mint(mintTo_, slot_, value_);
		ISFTIssuableConcrete(concrete()).mintOnlyDelegate(txSender_, currency_, mintTo_, slot_, tokenId_, value_);
		emit MintValue(tokenId_, slot_, value_);
	}	

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory) {
		bytes32[] memory existAddresses = super._resolverAddressesRequired();
		bytes32[] memory newAddresses = new bytes32[](1);
		newAddresses[0] = Constants.CONTRACT_ISSUE_MARKET;
		return _combineArrays(existAddresses, newAddresses);
	}

	function _issueMarket() internal view virtual returns (address) {
		return getRequiredAddress(Constants.CONTRACT_ISSUE_MARKET, "SFTIssuableDelegate: issueMarket not set");
	}

	uint256[50] private __gap;
}