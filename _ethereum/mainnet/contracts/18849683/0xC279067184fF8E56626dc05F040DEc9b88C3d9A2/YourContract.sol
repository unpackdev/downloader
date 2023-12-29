// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Ownable.sol";

contract ProfilePicture is ERC721, Ownable {
	mapping(uint256 tokenId => string) private _tokenURIs;

	constructor(address manager) ERC721("ProfilePicture", "PFP") {
		_transferOwnership(manager);
	}

	function setPFP(string memory uri) public {
		uint256 tokenId = uint256(uint160(msg.sender));

		if (_ownerOf(tokenId) == address(0)) {
			_safeMint(msg.sender, tokenId);
		}

		_tokenURIs[tokenId] = uri;
	}

	function pfpFor(address user) public view returns (string memory) {
		return tokenURI(uint256(uint160(user)));
	}

	// The following functions are overrides required by Solidity.

	function tokenURI(
		uint256 tokenId
	) public view override(ERC721) returns (string memory) {
		return super.tokenURI(tokenId);
	}

	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721) {
		require(uint160(from) == 0);
		super._transfer(from, to, tokenId);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view override(ERC721) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
