// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableInternal.sol";
import "./ERC165Storage.sol";
import "./Diamond.sol";
import "./IERC1155.sol";
import "./IERC1155Internal.sol";
import "./IERC1155Metadata.sol";
import "./ERC1155MetadataStorage.sol";

import "./IERC2771Recipient.sol";

import "./IERC2981Royalties.sol";
import "./ERC2981Storage.sol";
import "./OpenSeaCompatible.sol";
import "./OpenSeaProxyStorage.sol";

import "./ERC1155NSBaseStorage.sol";

import "./EventsStorage.sol";

contract EventsProxy is Diamond {
	using ERC165Storage for ERC165Storage.Layout;

	constructor() {
		ERC165Storage.layout().setSupportedInterface(type(IERC1155).interfaceId, true);
		ERC165Storage.layout().setSupportedInterface(type(IERC1155Metadata).interfaceId, true);
		ERC165Storage.layout().setSupportedInterface(type(IERC2771Recipient).interfaceId, true);
		ERC165Storage.layout().setSupportedInterface(type(IERC2981Royalties).interfaceId, true);
	}
}

contract EventsProxyInitializer is IERC1155Internal {
	function init(
		RoyaltyInfo memory royaltyInit,
		address opensea721Proxy,
		address opensea1155Proxy,
		address[] memory authorized,
		string memory contractUri,
		string memory baseURI
	) external {
		// Init ERC1155 Metadata
		ERC1155MetadataStorage.layout().baseURI = baseURI;
		OpenSeaCompatibleStorage.layout().contractURI = contractUri;

		EventsStorage.layout().index = 1;

		// Init Authorized Minters
		for (uint256 index = 0; index < authorized.length; index++) {
			EventsStorage.layout().authorized[authorized[index]] = true;
		}

		// Init Royalties
		ERC2981Storage.layout().royalties = royaltyInit;

		// Init Opensea Proxy
		OpenSeaProxyStorage._setProxies(opensea721Proxy, opensea1155Proxy);
	}
}
