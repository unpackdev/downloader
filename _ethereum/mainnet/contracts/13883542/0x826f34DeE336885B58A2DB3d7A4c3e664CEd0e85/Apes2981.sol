// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enumerable.sol";
import "./HookPausable.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./SafeMath.sol";

/**
 * Reference implementation of ERC721 with Enumerable and Counter support
 */
contract VapenApes2981 is ERC721Enumerable, HookPausable {
	/* ---------- Inheritance for solidity types ---------------- */
	using SafeMath for uint256;
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIdTracker;
	/* ---------- Inheritance for solidity types ---------------- */

	// uint256 public constant reveal_timestamp = 1627588800; // Thu Jul 29 2021 20:00:00 GMT+0000

	uint256 public startingIndexBlock;
	uint256 public startingIndex;
	bool public SALE_ACTIVE = false;
	uint256 public constant APE_SALEPRICE = 70000000000000000; //0.70 ETH
	uint256 public constant APE_PRESALE_PRICE = 55000000000000000; //0.55 ETH
	uint256 public constant MAX_APE_PURCHASE = 10;
	address public constant DEV_ADDRESS = 0x02fA4fe6cBfa5dC167dDD06727906d0F884351e3;
	uint256 public constant MAX_APES = 10000;

	/* PRESALE CONFIGURATION */

	uint256 public constant MAX_PRESALE = 4000;
	uint256 public constant MAX_PRESALE_PURCHASE = 5;
	uint256 public constant NUM_TO_RESERVE = 50;
	bool public PRESALE_ACTIVE = false;
	uint256 public PRESALE_MINTED;

	mapping(address => uint256) public PRESALE_PURCHASES;

	/* Team structure */
	struct Team {
		address payable addr;
		uint256 percentage;
	}
	Team[] internal _team;

	/**
	 * @dev
	 * Vapenapes Reveal configuration and handles for Metadata
	 */
	string public apesReveal = "";
	string public baseTokenURI;
	uint256 public revealTimestamp;

	/* Events and logs */
	event MintApe(uint256 indexed id);

	constructor() ERC721("VapenApes", "VAPE") {
		pause(true);

		/* Add all team mates to the equity mapping */
		_team.push(Team(payable(DEV_ADDRESS), 31));
		_team.push(Team(payable(0x3358294509A59A8fF942fD61e7F1429a418d015C), 31)); /* d */
		_team.push(Team(payable(0xb45FA3C125AB4dBe6ec5434E6462D7682382a1b4), 31)); /* J */
		/* $SEEDZ dev & marketing */
		_team.push(Team(payable(0x7369BAce49A85D89253634b15aC40597ae7a7Be6), 7));
	}

	/**
	 * @dev
	 * Encode team distribution percentage
	 * Embed all individuals equity and payout to seedz project
	 * retain at least 0.1 ether in the smart contract
	 */

	function withdraw() public onlyOwner {
		/* Minimum balance */
		require(address(this).balance > 0.5 ether);
		uint256 balance = address(this).balance - 0.1 ether;

		for (uint256 i = 0; i < _team.length; i++) {
			Team storage _st = _team[i];
			_st.addr.transfer((balance * _st.percentage) / 100);
		}
	}

	/* Extends HookPausable */
	function pause(bool val) public onlyOwner {
		if (val == true) {
			_pause();
			return;
		}
		_unpause();
	}

	modifier saleIsOpen() {
		require(SALE_ACTIVE, "Sale must be active to mint Ape");
		require(totalSupply() <= MAX_APES, "Sale end");
		if (_msgSender() != owner()) {
			require(!paused(), "Pausable: paused");
		}
		_;
	}

	/* Derives funcrtionality from Counter Library */
	function _totalSupply() internal view returns (uint256) {
		return _tokenIdTracker.current();
	}

	function totalMint() public view returns (uint256) {
		return _totalSupply();
	}

	/**
	 * @dev
	 * Sometimes tokens sent to contracts and get lostm, due to user errors
	 * This can enable withdrawal of any mistakenly send ERC-20 token to this address.
	 */
	function withdrawTokens(address tokenAddress) external onlyOwner {
		uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
		IERC20(tokenAddress).transfer(_msgSender(), balance);
	}

	/**
	 * Set some Apes aside
	 * We will set aside 50 Vapenapes for community giveaways and promotions
	 */
	function reserveApes() public onlyOwner {
		require(totalSupply().add(NUM_TO_RESERVE) <= MAX_APES, "Reserve would exceed max supply");

		uint256 supply = totalSupply();
		for (uint256 i = 0; i < NUM_TO_RESERVE; i++) {
			_safeMint(_msgSender(), supply + i);
		}
	}

	function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
		revealTimestamp = revealTimeStamp;
	}

	/*
	 * Set provenance once it's calculated
	 */
	function setProvenanceHash(string memory provenanceHash) public onlyOwner {
		apesReveal = provenanceHash;
	}

	function setBaseURI(string memory _baseTokenURI) public onlyOwner {
		_setBaseURI(_baseTokenURI);
	}

	/*
	 * Pause presale if active, make active if paused
	 */

	function flipSaleState() public onlyOwner {
		SALE_ACTIVE = !SALE_ACTIVE;
	}

	function flipPresaleState() external onlyOwner {
		PRESALE_ACTIVE = !PRESALE_ACTIVE;
	}

	function presalePurchasedCount(address addr) external view returns (uint256) {
		return PRESALE_PURCHASES[addr];
	}

	function presaleMintApe(uint256 numberOfTokens) external payable {
		require(PRESALE_ACTIVE, "Presale closed");
		require(PRESALE_MINTED + numberOfTokens <= MAX_PRESALE, "Purchase would exceed max presale");

		uint256 supply = totalSupply();
		require(supply.add(numberOfTokens) <= MAX_APES, "Purchase would exceed max supply of baddies");
		require(PRESALE_PURCHASES[_msgSender()] + numberOfTokens <= MAX_PRESALE_PURCHASE, "Purchase would exceed your max allocation");
		require(APE_PRESALE_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

		for (uint256 i = 0; i < numberOfTokens; i++) {
			/* Increment supply and mint token */
			_tokenIdTracker.increment();

			PRESALE_MINTED++;
			PRESALE_PURCHASES[_msgSender()]++;
			_safeMint(_msgSender(), supply);
		}
	}

	/**
	 * Mints Apes
	 */
	function mintApe(uint256 numberOfTokens) public payable saleIsOpen {
		require(numberOfTokens <= MAX_APE_PURCHASE, "Can only mint 20 tokens at a time");

		require(totalSupply().add(numberOfTokens) <= MAX_APES, "Purchase would exceed max supply of Apes");
		require(APE_SALEPRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

		for (uint256 i = 0; i < numberOfTokens; i++) {
			/* Increment supply and mint token */
			uint256 id = totalSupply();
			_tokenIdTracker.increment();

			/* For each number mint ape */
			if (totalSupply() < MAX_APES) {
				_safeMint(msg.sender, id);

				/* emit mint event */
				emit MintApe(id);
			}
		}

		// If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
		// the end of pre-sale, set the starting index block
		if (startingIndexBlock == 0 && (totalSupply() == MAX_APES || block.timestamp >= revealTimestamp)) {
			startingIndexBlock = block.number;
		}
	}

	/**
	 * Set the starting index for the collection
	 */
	function setStartingIndex() public {
		require(startingIndex == 0, "Starting index is already set");
		require(startingIndexBlock != 0, "Starting index block must be set");

		startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_APES;
		// Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
		if (block.number.sub(startingIndexBlock) > 255) {
			startingIndex = uint256(blockhash(block.number - 1)) % MAX_APES;
		}
		// Prevent default sequence
		if (startingIndex == 0) {
			startingIndex = startingIndex.add(1);
		}
	}

	function walletOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);

		uint256[] memory tokensId = new uint256[](tokenCount);
		for (uint256 i = 0; i < tokenCount; i++) {
			tokensId[i] = tokenOfOwnerByIndex(_owner, i);
		}

		return tokensId;
	}

	/**
	 * Set the starting index block for the collection, essentially unblocking
	 * setting starting index
	 */
	function emergencySetStartingIndexBlock() public onlyOwner {
		require(startingIndex == 0, "Starting index is already set");

		startingIndexBlock = block.number;
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override(ERC721Enumerable, HookPausable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
