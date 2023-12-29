// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

using ItemsHelper for ItemsById global;

library ItemsHelper {

	function add(
		ItemsById storage _items,
		uint256 _tokenId
	) internal {
		_items.array.push(_tokenId);
		_items.idx[_tokenId] = _items.array.length;
	}

	function remove(
		ItemsById storage _items,
		uint256 _tokenId
	) internal {

		uint256 arrayIdx = _items.idx[_tokenId] - 1;
		uint256 lastIdx = _items.array.length - 1;

		if (arrayIdx != lastIdx) {
			uint256 lastElement = _items.array[lastIdx];
			_items.array[arrayIdx] = lastElement;
			_items.idx[lastElement] = arrayIdx + 1;
		}

		_items.array.pop();

		delete _items.idx[_tokenId];
	}

	function exists(
		ItemsById storage _items,
		uint256 _tokenId
	) internal view returns (bool) {
		return _items.idx[_tokenId] != 0;
	}
}

/*
	Staked item storage alignment.
*/
struct ItemsById {
	uint256[] array;
	mapping ( uint256 => uint256 ) idx;
}

uint256 constant SINGLE_ITEM = 1;
uint256 constant PRECISION = 1e12;
uint256 constant WITHDRAW_BUFFER = 1 minutes;