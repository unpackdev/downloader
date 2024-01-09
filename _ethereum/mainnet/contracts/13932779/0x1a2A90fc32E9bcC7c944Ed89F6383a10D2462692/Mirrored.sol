// SPDX-License-Identifier: SPDX-License
pragma solidity ^0.8.6;

import "./console.sol";
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

contract Mirrored is ERC721, Ownable {
	address public sweetCooper = 0x35FB16Db88Bd1A37EFe58E4A936456c15065f713; // a⚡️c gnosis safe
	address private sweetAndy = 0x21868fCb0D4b262F72e4587B891B4Cf081232726;

	string public baseURI;

	uint128 private constant maxSupply = 80; // Max supply
	uint128 private saleLimitPerUser = 2;
	uint256 public listPrice = 200000000000000000; // 0.2 eth initial list price
	mapping(address => uint256) private premintMap; // Address paired w token ids for minting
	mapping(uint256 => address) private reservedTokenMap; // Reserved tokens paired with premint address
	mapping(address => uint128) private saleLimitMap; // Tally if user has made a purchase

	// Keep track of state
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIdCounter; // For keeping track of sequence
	Counters.Counter private _publicMintCounter; // For public sales
	Counters.Counter private _premintCounter; // For designated sales

	/**
	 * A bit wacky, but artist addresses and tokenIds are parallel arrays that
	 * compose into matching key-value pairs within premints.
	 *
	 * @param _baseURI base uri for tokens
	 * @param _premintAddresses list of premint address
	 */
	constructor(
		string memory _baseURI,
		address[] memory _premintAddresses,
		uint256[] memory _premintTokenIds
	) ERC721("Mirrored", "Mirrored") {
		require(
			_premintAddresses.length == _premintTokenIds.length,
			"CONSTRUCTOR_ARGS_MUST_BE_PARALLEL"
		);

		baseURI = _baseURI;

		for (uint128 i = 0; i < _premintAddresses.length; i++) {
			premintMap[_premintAddresses[i]] = _premintTokenIds[i];
			reservedTokenMap[_premintTokenIds[i]] = _premintAddresses[i];
		}
	}

	// General contract state
	/*------------------------------------*/

	/**
	 * Escape hatch to update price.
	 */
	function setPrice(uint128 _listPrice) public onlyOwner {
		listPrice = _listPrice;
	}

	/**
	 * Escape hatch to update URI.
	 */
	function setBaseURI(string memory _baseURI) public onlyOwner {
		baseURI = _baseURI;
	}

	/**
	 * Escape hatch to sales limit per user
	 */
	function setSalesLimit(uint128 _saleLimitPerUser) public onlyOwner {
		saleLimitPerUser = _saleLimitPerUser;
	}

	/**
	 * Update sweet baby cooper's address in the event of an emergency
	 */
	function setSweetCooper(address _sweetCooper) public {
		require(msg.sender == sweetAndy, "NOT_ANDY");
		sweetCooper = _sweetCooper;
	}

	/**
	 * Add a user's address to premint mapping for a specific token.
	 */
	function addToPremint(address _address, uint256 _tokenId) public onlyOwner {
		require(premintMap[_address] == 0, "ADDRESS_ALREADY_PREMINTED");
		require(!_exists(_tokenId), "TOKEN_ALLOCATED");

		premintMap[_address] = _tokenId;
		reservedTokenMap[_tokenId] = _address;
	}

	/**
	 * Remove a user from premint mapping.
	 * This can cause things to get out of phase if the tokenCounter
	 * is passed this point, but not super concerned.
	 */
	function removeFromPremint(address _address, uint256 _tokenId)
		public
		onlyOwner
	{
		require(premintMap[_address] != 0, "PREMINT_ADDRESS_DNE");
		require(reservedTokenMap[_tokenId] == _address, "RESERVE_TOKEN_DNE");

		delete premintMap[_address];
		delete reservedTokenMap[_tokenId];
	}

	/*
	 * Withdraw, sends:
	 * 95% of all past sales to artist.
	 * 5% of all past sales to devs.
	 */
	function withdraw() public onlyOwner {
		// Pass collaborators their cut
		uint256 balance = address(this).balance;

		// Send devs 4.95%
		(bool success, ) = sweetCooper.call{ value: (balance * 5) / 100 }("");
		require(success, "FAILED_SEND_DEV");

		// Send owner remainder
		(success, ) = owner().call{ value: (balance * 95) / 100 }("");
		require(success, "FAILED_SEND_OWNER");
	}

	// Minting
	/*------------------------------------*/

	/**
	 * Mint, updating storage of sales.
	 */
	function handleSale(uint256 _tokenId) private {
		_safeMint(msg.sender, _tokenId);
	}

	/**
	 * Keep track of counter states, passing any reserved tokens.
	 */
	function findNextTokenIndex() private {
		_tokenIdCounter.increment();

		while (reservedTokenMap[_tokenIdCounter.current()] != address(0)) {
			_tokenIdCounter.increment();
		}
	}

	/**
	 * Mint
	 */
	function publicMint() public payable {
		require(listPrice <= msg.value, "LOW_ETH");
		// Make sure user can only mint limit
		require(
			saleLimitMap[_msgSender()] < saleLimitPerUser,
			"MAX_LIMIT_PER_BUYER"
		);
		// Allocate for premint when checking max supply
		require(
			premintMap[_msgSender()] != 0 ||
				_tokenIdCounter.current() < maxSupply,
			"MAX_REACHED"
		);

		saleLimitMap[_msgSender()] = saleLimitMap[_msgSender()] + 1;

		// Handle designated mints, if an address is associated with a specific
		// token id.
		if (premintMap[_msgSender()] != 0) {
			uint256 _premintTokenId = premintMap[_msgSender()];

			require(!_exists(_premintTokenId), "TOKEN_ALLOCATED");
			_safeMint(msg.sender, _premintTokenId);

			_premintCounter.increment();
			delete premintMap[_msgSender()];
		} else {
			// Otherwise, this is a regular mint.
			_safeMint(msg.sender, _tokenIdCounter.current());

			_publicMintCounter.increment();
			findNextTokenIndex();
		}
	}

	// ERC721 Things
	/*------------------------------------*/

	/**
	 * Get total token supply
	 */
	function totalSupply() public view returns (uint256) {
		return _publicMintCounter.current() + _premintCounter.current();
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
