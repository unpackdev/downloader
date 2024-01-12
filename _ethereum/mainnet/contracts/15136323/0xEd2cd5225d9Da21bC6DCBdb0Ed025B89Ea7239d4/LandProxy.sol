// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableInternal.sol";
import "./ERC165Storage.sol";
import "./SolidStateDiamond.sol";
import "./IERC1155.sol";
import "./IERC1155Metadata.sol";
import "./ERC1155MetadataStorage.sol";

import "./IERC2981Royalties.sol";
import "./ERC2981Storage.sol";
import "./OpenSeaCompatible.sol";
import "./OpenSeaProxyStorage.sol";

import "./LandPriceStorage.sol";
import "./LandStorage.sol";
import "./LandTypes.sol";

contract LandProxy is SolidStateDiamond {
	using ERC165Storage for ERC165Storage.Layout;

	constructor() {
		ERC165Storage.layout().setSupportedInterface(type(IERC1155).interfaceId, true);
		ERC165Storage.layout().setSupportedInterface(type(IERC1155Metadata).interfaceId, true);
		ERC165Storage.layout().setSupportedInterface(type(IERC2981Royalties).interfaceId, true);
	}
}

contract LandProxyInitializer {
	function init(
		LandInitArgs memory landInit,
		RoyaltyInfo memory royaltyInit,
		address opensea721Proxy,
		address opensea1155Proxy,
		string memory contractURI,
		string memory baseURI
	) external {
		// Init ERC1155 Metadata
		ERC1155MetadataStorage.layout().baseURI = baseURI;
		OpenSeaCompatibleStorage.layout().contractURI = contractURI;

		// Init Land
		LandStorage.layout().mintState = uint8(MintState.CLOSED);
		LandStorage.layout().lions = landInit.lions;
		LandStorage.layout().icons = landInit.icons;
		LandStorage.layout().signer = landInit.signer;
		LandStorage.layout().zoneIndex = 2;

		// Init Price
		LandPriceStorage._setPrice(landInit.price);
		LandPriceStorage._setDiscountPrice(
			LandStorage._getIndexLionLands(),
			landInit.lionsDiscountPrice
		);

		LandStorage.layout().zones[LandStorage._getIndexSportsCity()] = landInit.zoneOne;
		LandStorage.layout().zones[LandStorage._getIndexLionLands()] = landInit.zoneTwo;

		// Init Royalties
		ERC2981Storage.layout().royalties = royaltyInit;

		// Init Opensea Proxy
		OpenSeaProxyStorage._setProxies(opensea721Proxy, opensea1155Proxy);
	}
}
