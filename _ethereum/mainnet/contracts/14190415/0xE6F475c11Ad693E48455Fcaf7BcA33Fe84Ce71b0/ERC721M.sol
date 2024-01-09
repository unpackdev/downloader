// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC721.sol";

abstract contract ERC721M is ERC721 {
	/* -------------------------------------------------------------------------- */
	/*                               ERC721M STORAGE                              */
	/* -------------------------------------------------------------------------- */

	/// @dev The index is the token ID counter and points to its owner.
	address[] internal _owners;

	/* -------------------------------------------------------------------------- */
	/*                                 CONSTRUCTOR                                */
	/* -------------------------------------------------------------------------- */

	constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
		// Initializes the index to 1.
		_owners.push();
	}

	/* -------------------------------------------------------------------------- */
	/*                              ENUMERABLE LOGIC                              */
	/* -------------------------------------------------------------------------- */

	/// @inheritdoc ERC721
	function totalSupply() public view override returns (uint256) {
		// Overflow is impossible as _owners.length is initialized to 1.
		unchecked {
			return _owners.length - 1;
		}
	}

	/// @dev O(totalSupply), it is discouraged to call this function from other contracts
	/// as it can become very expensive, especially with higher total collection sizes.
	/// @inheritdoc ERC721
	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
		require(index < balanceOf(owner), "INVALID_INDEX");

		// Both of the counters cannot overflow because the loop breaks before that.
		unchecked {
			uint256 count;
			uint256 _currentIndex = _owners.length; // == totalSupply() + 1 == _owners.length - 1 + 1
			for (uint256 i; i < _currentIndex; i++) {
				if (owner == ownerOf(i)) {
					if (count == index) return i;
					else count++;
				}
			}
		}

		revert("NOT_FOUND");
	}

	/// @inheritdoc ERC721
	function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
		require(_exists(index), "INVALID_INDEX");
		return index;
	}

	/* -------------------------------------------------------------------------- */
	/*                                ERC721 LOGIC                                */
	/* -------------------------------------------------------------------------- */

	/// @dev O(totalSupply), it is discouraged to call this function from other contracts
	/// as it can become very expensive, especially with higher total collection sizes.
	/// @inheritdoc ERC721
	function balanceOf(address owner) public view virtual override returns (uint256 balance) {
		require(owner != address(0), "INVALID_OWNER");

		unchecked {
			// Start at 1 since token 0 does not exist
			uint256 _currentIndex = _owners.length; // == totalSupply() + 1 == _owners.length - 1 + 1
			for (uint256 i = 1; i < _currentIndex; i++) {
				if (owner == ownerOf(i)) {
					balance++;
				}
			}
		}
	}

	/// @dev O(MAX_TX), gradually moves to O(1) as more tokens get transferred and
	/// the owners are explicitly set.
	/// @inheritdoc ERC721
	function ownerOf(uint256 id) public view virtual override returns (address owner) {
		require(_exists(id), "NONEXISTENT_TOKEN");

		for (uint256 i = id; ; i++) {
			owner = _owners[i];
			if (owner != address(0)) {
				return owner;
			}
		}
	}

	/* -------------------------------------------------------------------------- */
	/*                               INTERNAL LOGIC                               */
	/* -------------------------------------------------------------------------- */

	/// @inheritdoc ERC721
	function _mint(address to, uint256 amount) internal virtual override {
		require(to != address(0), "INVALID_RECIPIENT");
		require(amount != 0, "INVALID_AMOUNT");

		unchecked {
			uint256 _currentIndex = _owners.length; // == totalSupply() + 1 == _owners.length - 1 + 1

			for (uint256 i; i < amount - 1; i++) {
				// storing address(0) while also incrementing the index
				_owners.push();
				emit Transfer(address(0), to, _currentIndex + i);
			}

			// storing the actual owner
			_owners.push(to);
			emit Transfer(address(0), to, _currentIndex + (amount - 1));
		}
	}

	/// @inheritdoc ERC721
	function _exists(uint256 id) internal view virtual override returns (bool) {
		return id != 0 && id < _owners.length;
	}

	/// @inheritdoc ERC721
	function _transfer(
		address from,
		address to,
		uint256 id
	) internal virtual override {
		require(ownerOf(id) == from, "WRONG_FROM");
		require(to != address(0), "INVALID_RECIPIENT");
		require(msg.sender == from || getApproved(id) == msg.sender || isApprovedForAll(from, msg.sender), "NOT_AUTHORIZED");

		delete _tokenApprovals[id];

		_owners[id] = to;

		unchecked {
			uint256 prevId = id - 1;
			if (_owners[prevId] == address(0)) {
				_owners[prevId] = from;
			}
		}

		emit Transfer(from, to, id);
	}
}
