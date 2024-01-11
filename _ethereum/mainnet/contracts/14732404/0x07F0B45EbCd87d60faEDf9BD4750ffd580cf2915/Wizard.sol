// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721A.sol";
import "Ownable.sol";

contract Wizard is ERC721A, Ownable {
	mapping(address => bool) public isMinter;

	constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.lootbox.io/api/wizard/";
    }

	function safeMint(address to, uint256 quantity) public {
		require(isMinter[_msgSender()], "Caller is not minter.");
		_safeMint(to, quantity);
	}

	function setMinter(address minter, bool status) public onlyOwner {
		isMinter[minter] = status;
	}
}