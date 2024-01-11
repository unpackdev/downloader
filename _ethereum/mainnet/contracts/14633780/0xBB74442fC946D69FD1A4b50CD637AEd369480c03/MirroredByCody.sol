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

/// @notice struct for premint and winning auctions
struct Reserve {
	address reserveAddress;
	uint256 tokenPrice;
}

contract MirroredByCody is ERC721, Ownable {
	address public sweetAndy = 0x21868fCb0D4b262F72e4587B891B4Cf081232726; // a⚡️c
	string public baseURI;
	bool public isActive = false;

	uint128 supply; /// @notice count within a drop
	uint128 saleLimitPerUser; /// @notice sales limit for users within a drop
	bool isBlindMint; /// @notice if this is a blind mint or auction
	bool isSalesLimitEnforced; /// @notice is sales limit enforced for this drop
	uint256 listPrice; /// @notice list price for drop
	uint256 secretPrice; /// @notice list price for drop
	/// @dev all problems in computer science can be solved by another level of indirection
	uint8 dropCount = 0; // for keeping track of sequence
	mapping(uint8 => mapping(address => uint256)) public premintMap; /// @notice address paired w token ids for minting
	mapping(uint8 => mapping(uint256 => Reserve)) public reservedTokenMap; /// @notice Reserved tokens paired with premint address
	mapping(uint8 => mapping(address => uint128)) private saleLimitMap; /// @notice tally if user has made a purchase

	using Counters for Counters.Counter;
	Counters.Counter private tokenIdCounter; // for keeping track of token sequence

	/**
	 * @param baseURI_ base uri for tokens
	 */
	constructor(string memory baseURI_) ERC721("Mirrored", "Mirrored") {
		baseURI = baseURI_;
		supply = 75;
		saleLimitPerUser = 2;
		isBlindMint = true;
		isSalesLimitEnforced = true;
		listPrice = 20000000000000000; // 0.02 eth initial secret price
		secretPrice = 10000000000000000; // 0.01 eth initial list price
	}

	// General contract state
	/*------------------------------------*/

	/**
	 * @notice set active state
	 */
	function setIsActive(bool isActive_) public onlyOwner {
		isActive = isActive_;
	}

	/**
	 * @notice update URI.
	 */
	function setSweetAndy(address sweetAndy_) public onlyOwner {
		sweetAndy = sweetAndy_;
	}

	/**
	 * @notice update URI.
	 */
	function setBaseURI(string memory baseURI_) public onlyOwner {
		baseURI = baseURI_;
	}

	/**
	 * @notice set sales limit per user
	 */
	function setSalesLimitPerUser(uint128 saleLimitPerUser_) public onlyOwner {
		saleLimitPerUser = saleLimitPerUser_;
	}

	/**
	 * @notice set sales limit enforced
	 */
	function setIsBlindMint(bool isBlindMint_) public onlyOwner {
		isBlindMint = isBlindMint_;
	}

	/**
	 * @notice set sales limit enforced
	 */
	function setIsSalesLimitEnforced(bool isSalesLimitEnforced_)
		public
		onlyOwner
	{
		isSalesLimitEnforced = isSalesLimitEnforced_;
	}

	/**
	 * @notice update list price.
	 */
	function setListPrice(uint128 listPrice_) public onlyOwner {
		listPrice = listPrice_;
	}

	/**
	 * @notice update secret price.
	 */
	function setSecretPrice(uint128 secretPrice_) public onlyOwner {
		secretPrice = secretPrice_;
	}

	/**
	 * @notice set next drop
	 */
	function nextDrop(
		bool isBlindMint_,
		uint128 supply_,
		uint128 saleLimitPerUser_,
		bool isSalesLimitEnforced_,
		uint256 listPrice_,
		uint256 secretPrice_
	) public onlyOwner {
		/// @notice increment drop
		dropCount = dropCount + 1;

		isBlindMint = isBlindMint_;
		supply = supply_;
		saleLimitPerUser = saleLimitPerUser_;
		isSalesLimitEnforced = isSalesLimitEnforced_;
		listPrice = listPrice_;
		secretPrice = secretPrice_;
	}

	/**
	 * @notice Add a user's address to premint mapping for a specific token.
	 */
	function reserveToken(
		address reserveAddress,
		uint256 tokenId,
		uint256 tokenPrice
	) public {
		require(msg.sender == sweetAndy, "NOT_ANDY");
		require(
			premintMap[dropCount][reserveAddress] == 0,
			"ADDRESS_ALREADY_PREMINTED"
		);
		require(!_exists(tokenId), "TOKEN_ALLOCATED");

		premintMap[dropCount][reserveAddress] = tokenId;
		reservedTokenMap[dropCount][tokenId].reserveAddress = reserveAddress;
		reservedTokenMap[dropCount][tokenId].tokenPrice = tokenPrice;
	}

	/**
	 * @notice Remove a user from premint mapping.
	 * @dev if a token has been removed after the counter has passed it, it will need to be manually minted.
	 */
	function removeFromReserve(address reserveAddress, uint256 tokenId)
		public
		onlyOwner
	{
		require(
			premintMap[dropCount][reserveAddress] != 0,
			"RESERVE_TOKEN_DNE"
		);
		require(
			reservedTokenMap[dropCount][tokenId].reserveAddress != address(0),
			"PREMINT_ADDRESS_DNE"
		);

		delete premintMap[dropCount][reserveAddress];
		delete reservedTokenMap[dropCount][tokenId];
	}

	/**
	 * @notice withdraw, sends: 95% of all past sales to artist, 5% of all past sales to devs.
	 */
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;

		/// @notice send devs 4.95%
		(bool success, ) = sweetAndy.call{ value: (balance * 5) / 100 }("");
		require(success, "FAILED_SEND_DEV");

		/// @notice send owner remainder
		(success, ) = owner().call{ value: (balance * 95) / 100 }("");
		require(success, "FAILED_SEND_OWNER");
	}

	// Minting state
	/*------------------------------------*/
	/**
	 * @notice keep track of counter states, passing any reserved tokens.
	 */
	function findNextTokenIndex() private {
		tokenIdCounter.increment();

		while (
			reservedTokenMap[dropCount][tokenIdCounter.current()]
				.reserveAddress != address(0)
		) {
			tokenIdCounter.increment();
		}
	}

	/**
	 * @notice auction mint
	 */
	function auctionMint(uint256 tokenId) public payable {
		require(isActive, "NOT_ACTIVE");
		require(!isBlindMint, "NOT_AUCTION_MINT");
		require(
			reservedTokenMap[dropCount][tokenId].reserveAddress != address(0),
			"AUCTION_NOT_FINISHED"
		);
		require(
			reservedTokenMap[dropCount][tokenId].reserveAddress == msg.sender,
			"WRONG_SENDER"
		);
		require(
			reservedTokenMap[dropCount][tokenId].tokenPrice <= msg.value,
			"LOW_ETH"
		);
		require(!_exists(tokenId), "TOKEN_ALLOCATED");

		_safeMint(msg.sender, tokenId);
		tokenIdCounter.increment();
	}

	/**
	 * @notice blind mint
	 */
	function blindMint(bool isSpecial) public payable {
		require(isActive, "NOT_ACTIVE");
		require(isBlindMint, "NOT_BLIND_MINT");
		/// @notice make sure there is enough cash in message
		require((isSpecial ? secretPrice : listPrice) <= msg.value, "LOW_ETH");
		/// @notice make sure user can only mint limit
		require(
			saleLimitMap[dropCount][_msgSender()] < saleLimitPerUser,
			"MAX_LIMIT_PER_BUYER"
		);
		/// @notice allocate for premint when checking max supply
		require(
			premintMap[dropCount][_msgSender()] != 0 ||
				tokenIdCounter.current() < supply,
			"MAX_REACHED"
		);

		/// @dev only update sales limit if sales limit is enforced for drop
		if (isSalesLimitEnforced) {
			saleLimitMap[dropCount][_msgSender()] =
				saleLimitMap[dropCount][_msgSender()] +
				1;
		}

		/// @notice handle designated mints, if an address is associated with a specific token id
		if (premintMap[dropCount][_msgSender()] != 0) {
			uint256 premintTokenId = premintMap[dropCount][_msgSender()];

			require(!_exists(premintTokenId), "TOKEN_ALLOCATED");
			_safeMint(msg.sender, premintTokenId);
		} else {
			// Otherwise, this is a regular mint.
			_safeMint(msg.sender, tokenIdCounter.current());
			findNextTokenIndex();
		}
	}

	// ERC721 Things
	/*------------------------------------*/

	/**
	 * @notice get total token supply
	 */
	function totalSupply() public view returns (uint256) {
		return tokenIdCounter.current();
	}

	/**
	 * @notice get token URI
	 */
	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory)
	{
		require(_exists(tokenId), "TOKEN_DNE");
		return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
	}
}
