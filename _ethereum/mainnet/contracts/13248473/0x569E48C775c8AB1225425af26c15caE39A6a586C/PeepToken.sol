//SPDX-License-Identifier: MIT

/// @title ERC721 Peep Token
/// @author @MilkyTasteNFT MilkyTaste:8662 https://milkytaste.xyz
/// https://peeps.club
/// A diverse and family friendly NFT community

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract PeepToken is ERC721Tradable {
	using Strings for uint256;
	using SafeMath for uint256;

	address public FACTORY;

	// URIs
	string private placeholderURI;
	string private baseURI;
	uint256 private revealedTo;

	bool public BURN_ACTIVE = false;

	uint256 private nextTokenId = 1;
	uint256 public TOTAL_SUPPLY = 0;

	mapping(uint256 => string) public curatedURIs;

	constructor(address proxyRegistryAddress)
		ERC721Tradable('Peep', 'PEEP', proxyRegistryAddress)
	{
		placeholderURI = 'https://peeps.club/metadata/placeholder.json';
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
	 * @dev Requires the correct value for the amount provided.
	 */
	modifier onlyFactory() {
		require(msg.sender == FACTORY, 'PeepToken: must be called by factory');
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
	 * @dev Reveal up to the token id provided.
	 * @notice This is exclusive.
	 * @notice This does not affect curated tokens.
	 */
	function updateRevealedTo(uint256 newRevealedTo) external onlyOwner {
		require(newRevealedTo > revealedTo, 'PeepToken: must reveal more');
		revealedTo = newRevealedTo;
	}

	/**
	 * @dev Update a curated token URI
	 */
	function updateCuratedURI(uint256 tokenId, string memory curatedURI)
		external
		onlyOwner
	{
		require(
			bytes(curatedURIs[tokenId]).length > 0,
			'PeepToken: not a curated token'
		);
		curatedURIs[tokenId] = curatedURI;
	}

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 * We override this method because it's nice to have a .json file extension.
	 */
	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(_exists(tokenId), 'PeepToken: URI query for nonexistent token');

		string memory curatedURI = curatedURIs[tokenId];
		if (bytes(curatedURI).length > 0) {
			return curatedURI;
		}
		if (tokenId < revealedTo) {
			if (bytes(baseURI).length > 0) {
				return
					string(
						abi.encodePacked(baseURI, tokenId.toString(), '.json')
					);
			}
		}

		return placeholderURI;
	}

	//
	// Admin management
	//

	/**
	 * @dev Set factory
	 */
	function setFactory(address newFactory) external onlyOwner {
		FACTORY = newFactory;
	}

	/**
	 * @dev Toggle burn state
	 * @notice Do not enable sale when burn is active
	 */
	function toggleBurn() external onlyOwner {
		BURN_ACTIVE = !BURN_ACTIVE;
	}

	//
	// Minting
	//

	/**
	 * @dev Mint a curated token.
	 */
	function curatedMint(address addr, string memory curatedURI)
		external
		onlyOwner
	{
		curatedURIs[nextTokenId] = curatedURI;
		_safeMint(addr, nextTokenId);
		nextTokenId = nextTokenId.add(1);
		TOTAL_SUPPLY = TOTAL_SUPPLY.add(1);
	}

	/**
	 * @dev Do the minting here
	 */
	function doMint(address addr, uint256 amount) external onlyFactory {
		for (uint256 i = 0; i < amount; i++) {
			_safeMint(addr, nextTokenId);
			nextTokenId = nextTokenId.add(1);
		}
		TOTAL_SUPPLY = TOTAL_SUPPLY.add(amount);
	}

	//
	// Burning
	//

	/**
	 * @dev Burn token.
	 * Burning does not alter to total available mints.
	 */
	function burn(uint256 tokenId) external {
		require(BURN_ACTIVE, 'PeepToken: burning is disabled');
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			'PeepToken: caller is not owner nor approved'
		);
		_burn(tokenId);
		TOTAL_SUPPLY = TOTAL_SUPPLY.sub(1);
	}

	//
	// View methods
	//

	/**
	 * @dev Return the total supply.
	 */
	function totalSupply() external view returns (uint256) {
		return TOTAL_SUPPLY;
	}
}
