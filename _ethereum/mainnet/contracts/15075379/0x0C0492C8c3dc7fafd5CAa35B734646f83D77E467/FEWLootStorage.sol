// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract FEWLootStorage is ERC721Enumerable, Ownable {
	event LootBurnt(address indexed user, uint256 indexed loot);
	event LootClaimed(address indexed user, uint256 indexed loot);

    mapping(uint256 => bool) public usedNonces;

	string public _baseTokenURI;
	address public _signer;
    address _mainContract;

	constructor() ERC721("Forgotten Ethereal Loot", "FEL") {}
}
