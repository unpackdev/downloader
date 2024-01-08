// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

contract PixelMeowImpl is
	Initializable, ContextUpgradeable,
	OwnableUpgradeable,
	ERC721EnumerableUpgradeable,
	ERC721BurnableUpgradeable,
	ERC721PausableUpgradeable
{
	function initialize(
		string memory name,
		string memory symbol,
		string memory baseTokenURI
	) public virtual initializer {
		__Context_init_unchained();
		__ERC165_init_unchained();
		__Ownable_init_unchained();
		__ERC721_init_unchained(name, symbol);
		__ERC721Enumerable_init_unchained();
		__ERC721Burnable_init_unchained();
		__Pausable_init_unchained();
		__ERC721Pausable_init_unchained();

		_pause();

		_tokenIdTracker = 518;
		_baseTokenURI = baseTokenURI;
	}

	uint256 constant public BUYABLE = 10000;
	uint256 constant public PRICE = 15 ether / 1000;

	uint256 private _tokenIdTracker;
	string private _baseTokenURI;

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function setBaseURI(string memory baseTokenURI) public virtual onlyOwner {
		_baseTokenURI = baseTokenURI;
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

	function mintMeowForAirDrop(address to, uint256[] memory tokenIds) external onlyOwner {
		require(!_isContract(to), "Caller cannot be contract");

		for (uint256 i = 0; i < tokenIds.length; i++){
			uint256 tokenId = tokenIds[i];
			require(tokenId < 518, "Only mint tokenId less 518");
			_mint(to, tokenId);
		}
	}

	function mintMeow(uint256 amount) public payable {
		require(amount <= 100, "Can only mint 100 tokens at a time");
		require(msg.value >= PRICE * amount, "Incorrect price");
		require(_tokenIdTracker + amount <= BUYABLE, "Exceed max supply");
		require(!_isContract(_msgSender()), "Caller cannot be contract");

		for (uint256 i = 0; i < amount; i++){
			_mint(_msgSender(), _tokenIdTracker);
			_tokenIdTracker += 1;
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
