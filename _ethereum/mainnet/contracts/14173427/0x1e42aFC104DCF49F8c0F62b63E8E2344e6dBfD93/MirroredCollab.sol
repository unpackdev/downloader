// SPDX-License-Identifier: SPDX-License
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

/*
a⚡️c

███╗░░░███╗██╗██████╗░██████╗░░█████╗░██████╗░███████╗██████╗░
████╗░████║██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
██╔████╔██║██║██████╔╝██████╔╝██║░░██║██████╔╝█████╗░░██║░░██║
██║╚██╔╝██║██║██╔══██╗██╔══██╗██║░░██║██╔══██╗██╔══╝░░██║░░██║
██║░╚═╝░██║██║██║░░██║██║░░██║╚█████╔╝██║░░██║███████╗██████╔╝
╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░

* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *

╗═╔░░░░░╗═╔╗═╔╗═╔░░╗═╔╗═╔░░╗═╔░╗════╔░╗═╔░░╗═╔╗══════╔╗═════╔░
██║░╗═╔░██║██║██║░░██║██║░░██║╗█████╝╔██║░░██║███████╚██████╝╔
██║╗██╝╔██║██║██╝══██╚██╝══██╚██║░░██║██╝══██╚██╝══╔░░██║░░██║
██╝████╝██║██║██████╝╔██████╝╔██║░░██║██████╝╔█████╚░░██║░░██║
████╚░████║██║██╝══██╚██╝══██╚██╝══██╚██╝══██╚██╝════╔██╝══██╚
███╚░░░███╚██╚██████╚░██████╚░░█████╚░██████╚░███████╚██████╚░

ɐ⚡️ɔ
*/

struct Bid {
	address bidderAddress;
	uint256 bidAmount;
}

struct Sale {
	uint256 tokenId;
	uint256 saleAmount;
}

contract MirroredCollab is ERC721, Ownable {
	string public baseURI;
	using Counters for Counters.Counter;
	Counters.Counter private counter;
	address public sweetCooper = 0xeb68669D321E1459900D83595818cE1313a4d90f;
	address public sweetAndy = 0x21868fCb0D4b262F72e4587B891B4Cf081232726;

	mapping(uint256 => address) private artistTokenMap; // Collaborator paired w token id
	mapping(uint256 => Bid) private wonAuctionsMap;
	Sale[] private pastSales; // List of past sales

	/**
	 * Set baseURI and artist addresses mapped to their tokens.
	 * @param _baseURI list of artist addresses
	 * @param _artistAddresses list of artist addresses
	 */
	constructor(string memory _baseURI, address[] memory _artistAddresses)
		ERC721("MirroredCollab", "MirroredCollab")
	{
		baseURI = _baseURI;

		// Set artist royalty key value map
		for (uint128 i = 0; i < _artistAddresses.length; i++) {
			artistTokenMap[i] = _artistAddresses[i];
		}
	}

	// General contract state
	/*------------------------------------*/

	/**
	 * Escape hatch to update URI.
	 */
	function setBaseURI(string memory _baseURI) public onlyOwner {
		baseURI = _baseURI;
	}

	/**
	 * Update sweet baby cooper's address in the event of an emergency
	 */
	function setSweetCooper(address _sweetCooper) public {
		require(msg.sender == sweetAndy, "NOT_ANDY");
		sweetCooper = _sweetCooper;
	}

	/**
	 * Update sweet baby cooper's address in the event of an emergency
	 */
	function setSweetAndy(address _sweetAndy) public onlyOwner {
		sweetAndy = _sweetAndy;
	}

	/**
	 * Add a collaborators's address to royalty mapping.
	 */
	function addToArtistToken(uint128 _tokenId, address _address)
		public
		onlyOwner
	{
		artistTokenMap[_tokenId] = _address;
	}

	/**
	 * Remove a collaborators's address from mint royalty.
	 */
	function removeFromArtistToken(uint128 _tokenId) public onlyOwner {
		delete artistTokenMap[_tokenId];
	}

	/*
	 * Withdraw, sends:
	 * 50% of all past sales to artist.
	 * ~45% of all past sales to collaborator.
	 * ~5% of all past sales to devs.
	 */
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;

		// Pass collaborators their cut
		for (uint256 i = 0; i < pastSales.length; i++) {
			Sale memory pastSale = pastSales[i];
			uint256 collaboratorCut = (pastSale.saleAmount * 45) / 100;
			balance = balance - collaboratorCut;

			address artistAddress = artistTokenMap[pastSales[i].tokenId];
			(bool artistSuccess, ) = artistAddress.call{
				value: collaboratorCut
			}("");
			require(artistSuccess, "FAILED_SEND_ARTIST");
		}

		delete pastSales;

		// Send devs 4.95%
		(bool success, ) = sweetCooper.call{ value: (balance * 9) / 100 }("");
		require(success, "FAILED_SEND_DEV");

		// Send owner remainder
		(success, ) = owner().call{ value: (balance * 91) / 100 }("");
		require(success, "FAILED_SEND_OWNER");
	}

	// Minting
	/*------------------------------------*/

	/**
	 * Mint, updating storage of sales.
	 */
	function mint(uint256 _tokenId) public payable {
		require(
			wonAuctionsMap[_tokenId].bidderAddress != address(0),
			"AUCTION_NOT_FINISHED"
		);
		require(
			wonAuctionsMap[_tokenId].bidderAddress == msg.sender,
			"WRONG_SENDER"
		);
		require(wonAuctionsMap[_tokenId].bidAmount <= msg.value, "LOW_ETH");
		require(!_exists(_tokenId), "TOKEN_ALLOCATED");

		_safeMint(msg.sender, _tokenId);

		if (artistTokenMap[_tokenId] != address(0)) {
			pastSales.push(Sale({ tokenId: _tokenId, saleAmount: msg.value }));
		}

		counter.increment();
	}

	function addToWonAuction(
		uint256 _tokenId,
		address _bidderAddress,
		uint256 _bidAmount
	) public {
		require(!_exists(_tokenId), "TOKEN_ALLOCATED");
		require(msg.sender == sweetAndy, "NOT_ANDY");

		wonAuctionsMap[_tokenId] = Bid({
			bidderAddress: _bidderAddress,
			bidAmount: _bidAmount
		});
	}

	// ERC721 Things
	/*------------------------------------*/

	/**
	 * Get total token supply
	 */
	function totalSupply() public view returns (uint256) {
		return counter.current();
	}

	/**
	 * Get token URI
	 */
	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		require(_exists(_tokenId), "TOKEN_DNE");
		return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
	}
}
