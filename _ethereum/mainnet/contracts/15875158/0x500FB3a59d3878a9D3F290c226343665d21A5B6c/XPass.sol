// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Strings.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./ERC721URIStorage.sol";

import "./OwnableExtended.sol";
import "./Whitelist.sol";

contract XPass is ERC2981, ERC721URIStorage, Pausable, OwnableExtended, Whitelist  {
	event Create(address indexed to, uint id, Level level);

	using Strings for uint;
	using Counters for Counters.Counter;

	Counters.Counter private tokenIds;

	enum Level {
		Limbo,
		Adept,
		Expert,
		Master,
		Supreme,
		Xtoker
	}

	string private TOKEN_URI;
	string private CONTRACT_URI;

	uint[6] public levelToWeiPrice;
	uint[6] public levelToSupplyLimit;
	uint constant public maxSupply = 5050;
	mapping(uint => Level) public tokenIdToLevel;
	mapping(Level => uint) public levelToEmission;

	constructor(string memory _tokenURI, string memory _contractURI) ERC721("XPass", "XPASS") {
		TOKEN_URI = _tokenURI;
		CONTRACT_URI = _contractURI;
	}

	modifier inLevel(Level level) virtual {
		require(Level.Xtoker >= level, "Wrong level");
		require(levelToSupplyLimit[uint(level)] > levelToEmission[level], "Over level");
		require(tokenIds.current() < maxSupply, "Over supply");
		_;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return TOKEN_URI;
	}

	function setBaseURI(string memory _tokenURI, string memory _contractURI) public onlyOperator {
		TOKEN_URI = _tokenURI;
		CONTRACT_URI = _contractURI;
	}

	function enableWhitelist() external onlyOperator {
		_enableWhitelist();
	}

	function disableWhitelist() external onlyOperator {
		_disableWhitelist();
	}

	function addWhitelist(address account) external onlyOperator {
		_addWhitelist(account);
	}

	function addBulkWhitelist(address[] memory accounts) external onlyOperator {
		for (uint i = 0; i < accounts.length; i++) {
			_addWhitelist(accounts[i]);
		}
	}

	function setWhitelistLimit(uint _limit) external onlyOperator {
		_setWhitelistLimit(_limit);
	}

	function removeWhitelist(address account) external onlyOperator {
		_removeWhitelist(account);
	}

	function buyToken(Level level) public payable whenNotPaused whenUseWhitelist inLevel(level) {
		address caller = _msgSender();

		require(msg.value >= levelToWeiPrice[uint(level)], "Wrong price");

		if (useWhitelist()) {
			require(balanceOf(caller) <= whitelistMintLimit(), "Whitelist limit reached");
		}

		tokenIds.increment();
		uint tokenId = tokenIds.current();

		_mint(caller, tokenId);
		_setTokenURI(tokenId, tokenId.toString());

		levelToEmission[level]++;
		tokenIdToLevel[tokenId] = level;

		emit Create(caller, tokenId, level);
	}

	function mintToken(address owner, Level level) external onlyOperator whenNotPaused inLevel(level) {
		tokenIds.increment();
		uint tokenId = tokenIds.current();

		_mint(owner, tokenId);
		_setTokenURI(tokenId, tokenId.toString());

		levelToEmission[level]++;
		tokenIdToLevel[tokenId] = level;

		emit Create(owner, tokenId, level);
	}

	function setLevelsPrice(uint[6] memory levelsPriceInWei) external onlyOperator {
		levelToWeiPrice = levelsPriceInWei;
	}

	function setLevelsSupplyLimit(uint[6] memory levelsSupply) external onlyOperator {
		levelToSupplyLimit = levelsSupply;
	}

	function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOperator {
		_setDefaultRoyalty(receiver, feeNumerator);
	}

	function resetDefaultRoyalty() external onlyOperator {
		_deleteDefaultRoyalty();
	}

	function setTokenRoyalty(uint tokenId, address receiver, uint96 feeNumerator) external onlyOperator {
		_setTokenRoyalty(tokenId, receiver, feeNumerator);
	}

	function resetTokenRoyalty(uint tokenId) external onlyOperator {
		_resetTokenRoyalty(tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
		return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
	}

	function contractURI() public view returns (string memory) {
		return CONTRACT_URI;
	}

	function setPause() external onlyOperator {
		_pause();
	}

	function setUnpause() external onlyOperator {
		_unpause();
	}

	function totalSupply() public view returns (uint) {
		return tokenIds.current();
	}
}
