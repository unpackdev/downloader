//SPDX-License-Identifier: MIT

/// @title ERC721 Speedrun AI

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract SpeedrunAI is ERC721Tradable {
	using Strings for uint256;

	// URIs
	string private IPFS_BASE = 'ipfs://';
	string private placeholderURI;
	string private baseURI;
	uint256 private revealedTo;

	// Supply
	uint256 public saleToSeries = 1; // exclusive
	uint256 public totalSupply = 0;
	uint256 public maxTokenPerMint = 5;
	uint256 public pricePerToken = 0 ether;

	constructor(address proxyRegistryAddress)
		ERC721Tradable('SpeedrunAI', 'SRAI', proxyRegistryAddress)
	{
		placeholderURI = 'Qmaebd4N9ZgtYynC9uAhtFSz9qXJWRNzRGb5ygr4Yf1Sji';
		_doMint(msg.sender, 9); // Deployer get the first 9 (+1 per series)
	}

	/**
	 * @dev Withdraw funds to owner address.
	 */
	function withdraw(address payable withdrawTo) external onlyOwner {
		uint256 balance = address(this).balance;
		withdrawTo.transfer(balance);
	}

	//
	// Modifiers
	//

	/**
	 * Get the series of the given token.
	 * 100 tokens in a series.
	 */
	function getSeries(uint256 tokenId) public pure returns (uint256) {
		return (tokenId / 100) + 1;
	}

	/**
	 * @dev Requires the correct value for the amount provided.
	 */
	modifier seriesSaleOn(uint256 tokenId) {
		require(
			getSeries(tokenId) < saleToSeries,
			'SpeedrunAI: series not on sale'
		);
		_;
	}

	/**
	 * @dev Requires the caller not be a contract.
	 */
	modifier notContract() {
		require(tx.origin == msg.sender, 'SpeedrunAI: contracts are banned');
		_;
	}

	//
	// URI Methods
	//

	/**
	 * @dev Update the placeholder URI
	 */
	function setPlaceholderURI(string memory newURI) external onlyOwner {
		placeholderURI = newURI;
	}

	/**
	 * @dev Update the base URI
	 */
	function setBaseURI(string memory newURI) external onlyOwner {
		baseURI = newURI;
	}

	/**
	 * @dev Reveal up to the series provided.
	 * @notice This is exclusive.
	 */
	function revealToSeries(uint256 newRevealedTo) external onlyOwner {
		revealedTo = newRevealedTo;
	}

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 */
	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(
			_exists(tokenId),
			'SpeedrunAI: URI query for nonexistent token'
		);

		if (getSeries(tokenId) < revealedTo && bytes(baseURI).length > 0) {
			return
				string(
					abi.encodePacked(
						IPFS_BASE,
						baseURI,
						'/',
						tokenId.toString(),
						'.json'
					)
				);
		}

		return string(abi.encodePacked(IPFS_BASE, placeholderURI));
	}

	//
	// Sale management
	//

	/**
	 * @dev Sets the cost per token
	 */
	function setTokenPrice(uint256 newCostPerToken) external onlyOwner {
		pricePerToken = newCostPerToken;
	}

	/**
	 * @dev Sets the max mintable per transaction
	 */
	function setMaxPerMint(uint256 newMaxPerMint) external onlyOwner {
		maxTokenPerMint = newMaxPerMint;
	}

	/**
	 * @dev Releases the next series
	 */
	function releaseNextSeries() external onlyOwner {
		saleToSeries += 1;
		_doMint(msg.sender, 1); // Mints one to the owner
	}

	//
	// Minting
	//

	/**
	 * @dev Mint tokens
	 */
	function mint(address addr, uint256 amount)
		external
		payable
		seriesSaleOn(totalSupply + amount - 1)
		notContract
	{
		require(
			msg.value >= amount * pricePerToken,
			'SpeedrunAI: incorrect amount'
		);
		require(amount <= maxTokenPerMint, 'SpeedrunAI: too many tokens');
		_doMint(addr, amount);
	}

	/**
	 * @dev Do the minting here
	 */
	function _doMint(address addr, uint256 amount) internal {
		for (uint256 i = 0; i < amount; i++) {
			_safeMint(addr, totalSupply + i);
		}
		totalSupply += amount;
	}
}
