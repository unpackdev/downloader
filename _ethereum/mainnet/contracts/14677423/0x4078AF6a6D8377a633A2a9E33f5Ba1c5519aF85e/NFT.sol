// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721OpenSea.sol";

contract Boolets is Ownable, ERC721OpenSea {
	uint256 public constant FREE_SUPPLY = 222;
	uint256 public constant TOTAL_SUPPLY = 1111;
	uint256 public constant MAX_QTY_PER_MINTER = 6;
	uint256 public constant MAX_MINT_PER_TX = 3;
	uint256 public constant SALE_PRICE = 0.01 ether;

	mapping(address => uint256) public salesMinterToTokenQty;

	uint256 public salesMintedQty = 0;

	constructor() ERC721("Boolets", "BOOLETS") {}

	function mint(uint256 _mintQty) external payable {
		require(salesMintedQty + _mintQty <= TOTAL_SUPPLY, "Sold out");
		require(
			salesMinterToTokenQty[msg.sender] + _mintQty <= MAX_QTY_PER_MINTER,
			"Max mint exceeded"
		);
		require(_mintQty <= MAX_MINT_PER_TX, "Max 3 mint per tx");
		require(tx.origin == msg.sender, "Contracts not allowed");

		if (
			salesMintedQty > FREE_SUPPLY ||
			salesMintedQty + _mintQty > FREE_SUPPLY
		) {
			require(msg.value >= _mintQty * SALE_PRICE, "Insufficient ETH");
		}

		salesMinterToTokenQty[msg.sender] += _mintQty;
		salesMintedQty += _mintQty;

		for (uint256 i = 0; i < _mintQty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	function withdraw() external onlyOwner {
		require(address(this).balance > 0, "No amount to withdraw");
		payable(msg.sender).transfer(address(this).balance);
	}
}
