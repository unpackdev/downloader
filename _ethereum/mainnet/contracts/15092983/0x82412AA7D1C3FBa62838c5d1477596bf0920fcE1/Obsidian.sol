// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Pausable.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Obsidian is ERC721, ERC721Royalty, Pausable, Ownable {
	string public defaultBaseURI;

	using Counters for Counters.Counter;
	Counters.Counter private tokenIdCounter;

	constructor() ERC721("Obsidian Collection MLK 1966", "Token") {
		tokenIdCounter.increment();
	}

	function mint(address[] memory to, uint256[] memory numTokens) public onlyOwner {
		for (uint256 i = 0; i < to.length; i++) {
			for (uint256 j = 0; j < numTokens[i]; j++) {
				safeMint(to[i]);
			}
		}
	}

	function safeMint(address to) private {
		_safeMint(to, tokenIdCounter.current());
		tokenIdCounter.increment();
	}

	function _baseURI() internal view override returns (string memory) {
		return defaultBaseURI;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		defaultBaseURI = _newBaseURI;
	}

	function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
		super._burn(tokenId);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		return super.tokenURI(tokenId);
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function setRoyalties(address recipient, uint96 fraction) external onlyOwner {
		_setDefaultRoyalty(recipient, fraction);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721) whenNotPaused {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	// The following functions are overrides required by Solidity.
	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
