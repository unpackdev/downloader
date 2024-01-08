//SPDX-License-Identifier: MIT
//Author: @MilkyTasteNFT MilkyTaste:8662
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";

contract MilkToken is ERC721Enumerable, Ownable {

	using Strings for uint256;
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;

	// Used for placeholder
	string private placeholderURI;
	string private baseURI;

	uint256 public tokenPrice = 5000000000000000; // 0.005 ETH
	uint256 private _supplyCap = 25;

	mapping(uint256 => bool) private _tokenRevealed;

	constructor() ERC721('MilkToken', 'MILK') {
		placeholderURI = 'https://milkytaste.xyz/milktoken/placeholder.json';
		baseURI = 'https://milkytaste.xyz/milktoken/';
		doMintToken(_msgSender());
		_tokenRevealed[1] = true;
	}

	/**
	 * @dev Only allow one token per address.
	 */
	modifier canOwnMore(address _to) {
		require(ERC721.balanceOf(_to) < 1, 'MilkToken: cannot own more MilkTokens');
		_;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override canOwnMore(to) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	/**
	 * @dev Withdraw funds to owner address.
	 */
	function withdraw(address payable withdrawTo) public onlyOwner {
		uint balance = address(this).balance;
		withdrawTo.transfer(balance);
	}

	/**
	 * @dev Withdraw funds to owner address.
	 */
	function setTokenPrice(uint256 newTokenPrice) public onlyOwner {
		tokenPrice = newTokenPrice;
	}

	/**
	 * @dev Update the placeholder URI and clear the baseURI
	 */
	function setPlaceholderURI(string memory newURI) external onlyOwner {
		placeholderURI = newURI;
		baseURI = '';
	}

	/**
	 * @dev Update the base URI
	 */
	function setBaseURI(string memory newURI) external onlyOwner {
		baseURI = newURI;
	}

	/**
	 * @dev Update the base URI
	 */
	function setSupplyCap(uint256 newSupplyCap) external onlyOwner {
		_supplyCap = newSupplyCap;
	}

	/**
	 * @dev Reveal a token
	 */
	function revealToken(uint256 tokenId) external onlyOwner {
		_tokenRevealed[tokenId] = true;
	}

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "MilkToken: URI query for nonexistent token");

		if (_tokenRevealed[tokenId] && bytes(baseURI).length > 0) {
			return string(abi.encodePacked(baseURI, tokenId.toString(), '.json'));
		}

		return placeholderURI;
	}

	/**
	 * @dev Mints a new token
	 */
	function mintToken(address addr) public canOwnMore(addr) payable returns (uint256) {
		require(msg.value == tokenPrice, "MilkToken: ether value incorrect");
		return doMintToken(addr);
	}

	/**
	 * @dev Owner can mint for free
	 */
	function ownerMintToken(address addr) public onlyOwner returns (uint256) {
		return doMintToken(addr);
	}

	/**
	 * @dev Do the minting here
	 */
	function doMintToken(address addr) internal canOwnMore(addr) returns (uint256) {
		require(_tokenIds.current() < _supplyCap, 'MilkToken: supply cap reached');

		_tokenIds.increment();
		uint256 id = _tokenIds.current();

		_safeMint(addr, id);
		return id;
	}

	/**
		* @dev Return the total supply
		*/
	function supplyCap() public view virtual returns (uint256) {
		return _supplyCap;
	}
}
