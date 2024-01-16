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

contract DigiPenguinsFounderPass is
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

		_baseTokenURI = baseTokenURI;
	}

	using SafeMathUpgradeable for uint256;
	using StringsUpgradeable for uint256;

	string private _baseTokenURI;

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

	function mintForAirDrop(address[] memory addresses, uint256[] memory tokenIds) external onlyOwner {
        require(addresses.length == tokenIds.length && tokenIds.length > 0, "addresses and tokenIds length mismatch");

		for (uint256 i = 0; i < tokenIds.length; i++){
			address to = addresses[i];
			uint256 tokenId = tokenIds[i];

			_mint(to, tokenId);
		}
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
