// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract NFT is ERC721Enumerable, Ownable {
	string private _baseURIextended;

	constructor(string memory name, string memory symbol)
		ERC721(name, symbol)
	{}

	function mint(address to) public {
		_safeMint(to, totalSupply());
	}

	function mint(address to, uint256 amount) public {
		uint256 start = totalSupply();
		uint256 end = start + amount;
		for (uint256 id = start; id < end; id++) _safeMint(to, id);
	}

	function setBaseURI(string memory baseURI_) external onlyOwner {
		_baseURIextended = baseURI_;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseURIextended;
	}
}