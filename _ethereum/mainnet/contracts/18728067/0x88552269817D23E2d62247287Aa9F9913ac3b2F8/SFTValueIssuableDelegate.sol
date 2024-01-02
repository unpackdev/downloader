//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Constants.sol";
import "./ResolverCache.sol";
import "./BaseSFTDelegateUpgradeable.sol";
import "./ISFTValueIssuableDelegate.sol";
import "./ISFTValueIssuableConcrete.sol";
import "./SFTIssuableDelegate.sol";

error OnlyMarket();

abstract contract SFTValueIssuableDelegate is ISFTValueIssuableDelegate, SFTIssuableDelegate {

	event BurnValue(uint256 indexed tokenId, uint256 burnValue);

	function __SFTValueIssuableDelegate_init(
		address resolver_, string memory name_, string memory symbol_, uint8 decimals_, 
		address concrete_, address metadata_, address owner_
	) internal onlyInitializing {
		__SFTIssuableDelegate_init(resolver_, name_, symbol_, decimals_, concrete_, metadata_, owner_);
	}

	function __SFTValueIssuableDelegate_init_unchained() internal onlyInitializing {
	}

	function mintValueOnlyIssueMarket(
		address txSender_, address currency_, uint256 tokenId_, uint256 mintValue_
	) external payable virtual override nonReentrant {
		if (_msgSender() != _issueMarket()) {
			revert OnlyMarket();
		}

		address owner = ERC3525Upgradeable.ownerOf(tokenId_);
		uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);

		ERC3525Upgradeable._mintValue(tokenId_, mintValue_);
		ISFTIssuableConcrete(concrete()).mintOnlyDelegate(txSender_, currency_, owner, slot, tokenId_, mintValue_);
		emit MintValue(tokenId_, slot, mintValue_);
	}

	function burnOnlyIssueMarket(uint256 tokenId_, uint256 burnValue_) external virtual override nonReentrant {
		if (_msgSender() != _issueMarket()) {
			revert OnlyMarket();
		}

		uint256 actualBurnValue = burnValue_ == 0 ? ERC3525Upgradeable.balanceOf(tokenId_) : burnValue_;
		ISFTValueIssuableConcrete(concrete()).burnOnlyDelegate(tokenId_, actualBurnValue);

		if (burnValue_ == 0) {
			ERC3525Upgradeable._burn(tokenId_);
		} else {
			ERC3525Upgradeable._burnValue(tokenId_, burnValue_);
		}
		emit BurnValue(tokenId_, actualBurnValue);
	}

	uint256[50] private __gap;
}