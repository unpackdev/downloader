// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum MintState {
	CLOSED,
	OPEN
}

struct Edition {
	uint8 state;
	uint16 count;
	uint16 max;
	uint64 price;
	uint8 limit; // purchase limit
}

library EventsStorage {
	struct Layout {
		uint256 index;
		mapping(uint256 => Edition) editions;
		mapping(address => bool) authorized;
		mapping(address => bool) proxies;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("io.partyanimalz.contracts.storage.EventsStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}

	// Adders

	function _addCount(uint256 tokenId, uint16 count) internal {
		Edition storage edition = _getEdition(tokenId);
		_addCount(edition, count);
	}

	function _addCount(Edition storage edition, uint16 count) internal {
		edition.count += count;
	}

	function _addEdition(Edition memory edition) internal {
		uint256 index = _getIndex();
		_addEdition(index, edition);
	}

	function _addEdition(uint256 index, Edition memory edition) internal {
		EventsStorage.layout().editions[index] = edition;
		index += 1;
		_setIndex(index);
	}

	// Getters

	function _getCount(uint256 tokenId) internal view returns (uint16) {
		return layout().editions[tokenId].count;
	}

	function _getEdition(uint256 tokenId) internal view returns (Edition storage) {
		return layout().editions[tokenId];
	}

	function _getIndex() internal view returns (uint256 index) {
		return layout().index;
	}

	function _getPrice(uint256 tokenId) internal view returns (uint64) {
		return layout().editions[tokenId].price;
	}

	function _getState(uint256 tokenId) internal view returns (MintState) {
		return MintState(layout().editions[tokenId].state);
	}

	// Setters

	function _setAuthorized(address target, bool allowed) internal {
		layout().authorized[target] = allowed;
	}

	function _setIndex(uint256 index) internal {
		layout().index = index;
	}

	function _setLimit(uint256 tokenId, uint8 limit) internal {
		layout().editions[tokenId].limit = limit;
	}

	function _setMaxCount(uint256 tokenId, uint16 maxCount) internal {
		layout().editions[tokenId].max = maxCount;
	}

	function _setPrice(uint256 tokenId, uint64 price) internal {
		layout().editions[tokenId].price = price;
	}

	function _setProxy(address proxy, bool enabled) internal {
		layout().proxies[proxy] = enabled;
	}

	function _setState(uint256 tokenId, MintState state) internal {
		layout().editions[tokenId].state = uint8(state);
	}
}
