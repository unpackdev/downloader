// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0;

import "./Denominations.sol";
import "./AccessControlUpgradeable.sol";
import "./IXanaliaAddressesStorage.sol";

contract XanaliaAddressesStorage is AccessControlUpgradeable, IXanaliaAddressesStorage {
	address public override xNftURI;
	address public override auctionDex;
	address public override marketDex;
	address public override offerDex;
	address public override xanaliaDex;
	address public override xanaliaTreasury;
	address public override collectionDeployer;
	address public override oldXanaliaDexProxy;

	function initialize() public initializer {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	modifier onlyAdmin() {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Xanalia: caller is not the admin");
		_;
	}

	function setXNftURI(address _xNftURI) public onlyAdmin {
		xNftURI = _xNftURI;
		emit XNftURIAddressChanged(xNftURI);
	}

	function setAuctionDex(address _auctionDex) public onlyAdmin {
		auctionDex = _auctionDex;
		emit AuctionDexChanged(auctionDex);
	}

	function setMarketDex(address _marketDex) public onlyAdmin {
		marketDex = _marketDex;
		emit MarketDexChanged(marketDex);
	}

	function setOfferDex(address _offerDex) public onlyAdmin {
		offerDex = _offerDex;
		emit OfferDexChanged(offerDex);
	}

	function setXanaliaDex(address _xanaliaDex) public onlyAdmin {
		xanaliaDex = _xanaliaDex;
		emit XanaliaDexChanged(xanaliaDex);
	}

	function setXanaliaTreasury(address _xanaliaTreasury) public onlyAdmin {
		xanaliaTreasury = _xanaliaTreasury;
		emit TreasuryChanged(xanaliaTreasury);
	}

	function setCollectionDeployer(address _collectionDeployer) public onlyAdmin {
		collectionDeployer = _collectionDeployer;
		emit DeployerChanged(collectionDeployer);
	}

	function setXanaliaDexProxy(address _oldXanaliaDexProxy) public onlyAdmin {
		oldXanaliaDexProxy = _oldXanaliaDexProxy;
		emit XanaliaDexProxyChanged(oldXanaliaDexProxy);
	}
}
