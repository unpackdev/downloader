// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";

contract NftPal721General is
	Initializable,
	UUPSUpgradeable,
	ERC721Upgradeable,
	ERC721EnumerableUpgradeable,
	ERC721URIStorageUpgradeable,
	PausableUpgradeable,
	ERC721BurnableUpgradeable,
	OwnableUpgradeable
{
	function initialize(string memory name_, string memory symbol_) public initializer {
		__ERC721_init(name_, symbol_);

		__Ownable_init();
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	/**
	 * @dev Function to mint tokens.
	 * @param to The address that will receive the minted tokens.
	 * @param tokenId The token id to mint.
	 * @param uri The token URI of the minted token.
	 * @return A boolean that indicates if the operation was successful.
	 */
	function mintWithTokenURI(
		address to,
		uint256 tokenId,
		string memory uri
	) public returns (bool) {
		_safeMint(to, tokenId);
		_setTokenURI(tokenId, uri);
		return true;
	}

	/**
	 * @dev Function to mint tokens. This helper function allows to mint multiple NFTs in 1 transaction.
	 * @param to The address that will receive the minted tokens.
	 * @param tokenId The token id to mint.
	 * @param uri The token URI of the minted token.
	 * @return A boolean that indicates if the operation was successful.
	 */
	function mintMultiple(
		address[] memory to,
		uint256[] memory tokenId,
		string[] memory uri
	) public returns (bool) {
		for (uint256 i = 0; i < to.length; i++) {
			_safeMint(to[i], tokenId[i]);
			_setTokenURI(tokenId[i], uri[i]);
		}
		return true;
	}

	function safeTransfer(
		address to,
		uint256 tokenId,
		bytes calldata data
	) public virtual {
		super._safeTransfer(_msgSender(), to, tokenId, data);
	}

	function safeTransfer(address to, uint256 tokenId) public virtual {
		super._safeTransfer(_msgSender(), to, tokenId, "");
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	// The following functions are overrides required by Solidity.

	function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
		super._burn(tokenId);
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
		returns (string memory)
	{
		return super.tokenURI(tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}
