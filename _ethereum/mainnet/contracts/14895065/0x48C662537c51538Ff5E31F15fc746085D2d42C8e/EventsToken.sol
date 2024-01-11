// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./console.sol";

import "./OwnableInternal.sol";

import "./ERC165.sol";
import "./ERC1155NSBase.sol";
import "./ERC1155NSBaseStorage.sol";
import "./ERC1155MetadataInternal.sol";

import "./OpenSeaProxyRegistry.sol";
import "./OpenSeaProxyStorage.sol";

import "./EventsStorage.sol";

contract EventsToken is OwnableInternal, ERC1155NSBase, ERC1155MetadataInternal, ERC165 {
	using EventsStorage for EventsStorage.Layout;

	modifier onlyAuthorized() {
		require(EventsStorage.layout().authorized[msg.sender] = true, "onlyAuthorized: not allowed");
		_;
	}

	modifier onlyEOA() {
		require(tx.origin == msg.sender, "onlyEOA: caller is contract");
		_;
	}

	// Overrides

	function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
		// check the 1155 proxy (it's the same on mainnet)
		address proxy1155 = OpenSeaProxyStorage.layout().os1155Proxy;
		if (LibOpenSeaProxy._isApprovedForAll(proxy1155, _owner, operator)) {
			return true;
		}

		// check the 721 proxy (it's the same on mainnet)
		address proxy721 = OpenSeaProxyStorage.layout().os721Proxy;
		if (LibOpenSeaProxy._isApprovedForAll(proxy721, _owner, operator)) {
			return true;
		}

		// our internal operators
		if (EventsStorage.layout().proxies[operator]) {
			return true;
		}
		return super.isApprovedForAll(_owner, operator);
	}

	function versionRecipient() external view virtual override returns (string memory) {
		return "2.2.5";
	}

	// Methods

	function mintEdition(uint256 tokenId, uint16 quantity) external payable onlyEOA {
		uint256 index = EventsStorage._getIndex();
		require(tokenId < index, "mintEdition: doesn't exist");

		Edition storage edition = EventsStorage._getEdition(tokenId);

		require(edition.state == uint8(MintState.OPEN), "mintEdition: sale closed");
		require(quantity > 0 && quantity <= edition.limit, "mintEdition: wrong quantity");
		require(quantity <= (edition.max - edition.count), "mintEdition: too many");
		require(msg.value == (quantity * edition.price), "mintEdition: wrong price");

		_unsafeMint(msg.sender, msg.sender, tokenId, quantity);

		EventsStorage._addCount(edition, quantity);
	}

	/**
	 * Creates a new edition of a token
	 * @param state The opening mint state
	 * @param maxCount the count of items
	 * @param price the price in wei
	 * @param limit the order limit
	 * @param tokenURI a token uri. if you leave this blank you will get the standard contract base, which is good for prereveals
	 */
	function createEdition(
		MintState state,
		uint16 maxCount,
		uint64 price,
		uint8 limit,
		string memory tokenURI
	) external onlyAuthorized {
		require(maxCount > 0, "mintEdition: mint a quantity");
		uint256 index = EventsStorage.layout().index;

		Edition memory edition = Edition(uint8(state), 0, maxCount, price, limit);

		_setTokenURI(index, tokenURI);
		EventsStorage._addEdition(index, edition);
	}

	/**
	 * Creates a new edition of a token and mints the supply to a specific address.
	 * @param recipient The wallet to receive the minted amount
	 * @param maxCount the count of items
	 * @param tokenURI a token uri. if you leave this blank you will get the standard contract base, which is good for prereveals
	 */
	function createEdition(
		address recipient,
		uint16 maxCount,
		string memory tokenURI
	) external onlyAuthorized {
		require(maxCount > 0, "mintEdition: mint a quantity");
		uint256 index = EventsStorage.layout().index;

		Edition memory edition = Edition(uint8(MintState.CLOSED), maxCount, maxCount, 0, 0);

		_unsafeMint(_msgSender(), recipient, index, maxCount);

		_setTokenURI(index, tokenURI);
		EventsStorage._addEdition(index, edition);
	}
}
