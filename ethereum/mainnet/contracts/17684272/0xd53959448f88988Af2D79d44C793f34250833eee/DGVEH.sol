// SPDX-License-Identifier: MIT
//
//
//  ________  ________  ________  ________  ________  _________
// |\   __  \|\   __  \|\   __  \|\   __  \|\   ____\|\___   ___\
// \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \  \___|\|___ \  \_|
//  \ \   __  \ \  \\\  \ \  \\\  \ \  \\\  \ \_____  \   \ \  \
//   \ \  \|\  \ \  \\\  \ \  \\\  \ \  \\\  \|____|\  \   \ \  \
//    \ \_______\ \_______\ \_______\ \_______\____\_\  \   \ \__\
//     \|_______|\|_______|\|_______|\|_______|\_________\   \|__|
//                                            \|_________|
//
//
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract DGVEH is ERC721Enumerable, Ownable {
	using Counters for Counters.Counter;

	// private variables
	Counters.Counter private _tokenIdCounter;
	string private _baseTokenURI;
	address private _minter;

	// events
	event MinterChanged(address indexed previousMinter, address indexed newMinter);

	constructor() ERC721("BOOOST Digital Vehicle", "DGVEH") {}

	/**
	 * @notice set minter of the contract to a new account (`newMinter`).
	 * can only be called by owner
	 * @param newMinter address of new minter
	 */
	function setMinter(address newMinter) public onlyOwner {
		require(newMinter != address(0), "setMinter: new minter is the zero address.");
		address oldMinter = _minter;
		_minter = newMinter;
		emit MinterChanged(oldMinter, newMinter);
	}

	/**
	 * @notice mint DGVEH
	 * can only be called by minter
	 * @param to address being minted to
	 */
	function mint(address to) public onlyMinter returns (uint256) {
		uint256 tokenId = _tokenIdCounter.current();
		_tokenIdCounter.increment();
		_safeMint(to, tokenId);
		return tokenId;
	}

	/**
	 * @notice set Base Token URI
	 * can only be called by owner
	 * @param baseTokenURI base URI of token
	 */
	function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
		_baseTokenURI = baseTokenURI;
	}

	/**
	 * @dev Burns `tokenId`. See {ERC721-_burn}.
	 * The caller must own `tokenId` or be an approved operator.
	 * @param tokenId id of the token
	 */
	function burn(uint256 tokenId) public {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
		_burn(tokenId);
	}

	/**
	 * @notice get next mint token ID
	 */
	function nextTokenId() public view returns (uint256) {
		return _tokenIdCounter.current();
	}

	/**
	 * @notice get all tokens of owner
	 */
	function tokensOfOwner(address owner) public view returns (uint256[] memory) {
		uint256 balance = balanceOf(owner);
		uint256[] memory tokens = new uint256[](balance);
		for (uint256 index = 0; index < balance; index++) {
			tokens[index] = tokenOfOwnerByIndex(owner, index);
		}
		return tokens;
	}

	/**
	 * @notice check minter
	 */
	modifier onlyMinter() {
		_checkMinter();
		_;
	}

	/**
	 * @notice throws if the sender is not the minter or owner.
	 */
	function _checkMinter() internal view {
		require(_minter == _msgSender() || owner() == _msgSender(), "_checkMinter: caller is not the minter or owner.");
	}

	//------------------//
	// Custom overrides //
	//------------------//
	/**
	 * @dev See {ERC721-_baseURI}
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}
}
