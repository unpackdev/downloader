// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";

contract DigiPenguins is
	Initializable, ContextUpgradeable,
	OwnableUpgradeable,
	ERC721EnumerableUpgradeable,
	ERC721BurnableUpgradeable,
	ERC721PausableUpgradeable
{
	function initialize(
		string memory name,
		string memory symbol,
		string memory baseTokenURI,
		address matchingContract
	) public virtual initializer {
		__Context_init_unchained();
		__ERC165_init_unchained();
		__Ownable_init_unchained();
		__ERC721_init_unchained(name, symbol);
		__ERC721Enumerable_init_unchained();
		__ERC721Burnable_init_unchained();
		__Pausable_init_unchained();
		__ERC721Pausable_init_unchained();

		_matchingContract = ERC721Upgradeable(matchingContract);
		_baseTokenURI = baseTokenURI;

		freeMintStartTime = 1664110800;												// 2022-09-25 13:00:00 UTC
		publicMintStartTime = freeMintStartTime + (60 * 60 * 50);					// 2022-09-27 15:00:00 UTC

		_publicMintedAmount = 0;
		_mutationTokenIdTracker = 8888;
	}

	ERC721Upgradeable private _matchingContract;

	using SafeMathUpgradeable for uint256;
	using StringsUpgradeable for uint256;

	string private _baseTokenURI;

	// Free Mint
	uint256 public freeMintStartTime;

	uint256 constant private freeMintDurationDays = 3;
	uint256 constant private freeMintLimitStep = 16;
	uint256 constant private freeMintDurationPerDay = 60 * 60 * 20;
	
	mapping(uint256 => uint256) public freeMintedAmountPerDay;

	// Public Mint
	uint256 public publicMintStartTime;
	uint256 public _publicMintedAmount;
	uint256 public _mutationTokenIdTracker;

	uint256 constant public publicMintEvolutionPrice = 3 ether / 100;				// 0.03 ETH
	uint256 constant public publicMintMutationPrice = 5 ether / 100;				// 0.05 ETH
	uint256 constant private publicMintLimited = 4000;

	// Reserved mint
	uint256 constant public reservedMintMutationPrice = 10 ether / 100;				// 0.1 ETH

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function setBaseURI(string memory baseTokenURI) external virtual onlyOwner {
		_baseTokenURI = baseTokenURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		string memory baseURI = _baseURI();
		string memory extName = '.json';
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extName)) : "";
	}

	function pause() public virtual onlyOwner {
		_pause();
	}

	function unpause() public virtual onlyOwner {
		_unpause();
	}

	function fetchSaleFunds() external onlyOwner {
		payable(_msgSender()).transfer(address(this).balance);
	}

	function freeMint(uint256 tokenId) external payable {
		require(block.timestamp >= freeMintStartTime, "Free mint not started");
		require(block.timestamp < publicMintStartTime, "Free mint is over");

		uint256 freeMintDuration = block.timestamp - freeMintStartTime;
		uint256 freeMintDays = uint256(freeMintDuration / (60 * 60 * 24));
		uint256 freeMintTime = uint256(freeMintDuration % (60 * 60 * 24));

		if (freeMintDays < 2){
			require(freeMintTime < freeMintDurationPerDay, "Today's free mint has ended");
		}

		// Check daily mint limit
		uint256 freeMintLimit = (freeMintDays + 1) * freeMintLimitStep;
		require(freeMintedAmountPerDay[freeMintDays] < freeMintLimit, "Today's free mint is sold out");

		require(!_isContract(_msgSender()), "Caller cannot be contract");
		require(_matchingContract.ownerOf(tokenId) == _msgSender(), "Need to hold the Digi Penguins Founder Pass of the corresponding tokenId");

		// Mint
		_mint(_msgSender(), tokenId);

		freeMintedAmountPerDay[freeMintDays] += 1;
	}

	function publicMint(uint16[] calldata evolutionTokenIds, uint8 mutationTokenAmount) external payable {
		// Check start and end
		require(block.timestamp >= publicMintStartTime, "Public mint not started");
		require(_publicMintedAmount < publicMintLimited, "Public mint is over");

		// Check amount
		require(evolutionTokenIds.length > 0 || mutationTokenAmount > 0, "Mint amount cannot be null");
		require(evolutionTokenIds.length <= 10 && mutationTokenAmount <= 10, "Evolution and Mutation up to 10 each");

		// Check mint limit
		require((_publicMintedAmount + evolutionTokenIds.length + mutationTokenAmount) <= publicMintLimited, "Exceed max supply");

		// Check payment
		uint256 evolutionTotalCost = publicMintEvolutionPrice * evolutionTokenIds.length;
		uint256 mutationTotalCost = publicMintMutationPrice * mutationTokenAmount;
		require(msg.value >= (evolutionTotalCost + mutationTotalCost), "Incorrect price");

		require(!_isContract(_msgSender()), "Caller cannot be contract");

		// Mint evolution
		if (evolutionTokenIds.length > 0) {
			for (uint8 i = 0; i < evolutionTokenIds.length; i++){
				uint256 evolutionTokenId = evolutionTokenIds[i];
				
				require(_matchingContract.ownerOf(evolutionTokenId) == _msgSender(), "Need to hold the Digi Penguins Founder Pass of the corresponding tokenId");

				_mint(_msgSender(), evolutionTokenId);

				_publicMintedAmount += 1;
			}
		}

		// Mint mutation
		if (mutationTokenAmount > 0) {
			for (uint8 i = 0; i < mutationTokenAmount; i++){

				_mint(_msgSender(), _mutationTokenIdTracker);
				_mutationTokenIdTracker += 1;

				_publicMintedAmount += 1;
			}
		}
	}

	function reservedMint(uint16[] calldata evolutionTokenIds) external payable {
		// Check start
		require(_publicMintedAmount >= publicMintLimited, "Reserved mint not started");

		// Check amount
		require(evolutionTokenIds.length > 0, "Mint amount cannot be null");
		require(evolutionTokenIds.length <= 10, "Evolution mint up to 10 at a time");

		// Check payment
		uint256 evolutionTotalCost = reservedMintMutationPrice * evolutionTokenIds.length;
		require(msg.value >= evolutionTotalCost, "Incorrect price");

		require(!_isContract(_msgSender()), "Caller cannot be contract");

		// Mint
		for (uint8 i = 0; i < evolutionTokenIds.length; i++){
			uint256 evolutionTokenId = evolutionTokenIds[i];
			
			require(_matchingContract.ownerOf(evolutionTokenId) == _msgSender(), "Need to hold the Digi Penguins Founder Pass of the corresponding tokenId");

			_mint(_msgSender(), evolutionTokenId);
		}
	}

	function _isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
	uint256[50] private __gap;
}
