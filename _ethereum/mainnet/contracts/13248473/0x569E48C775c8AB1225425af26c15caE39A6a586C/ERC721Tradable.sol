// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 * @author Opensea. Optimised by MilkyTaste
 * @dev Updated to use OpenZepplin's ERC721 instead of ERC721Enumerable.
 * @dev Removed a bunch of unnecessary methods.
 */
abstract contract ERC721Tradable is
	ContextMixin,
	ERC721,
	NativeMetaTransaction,
	Ownable
{
	using SafeMath for uint256;

	address proxyRegistryAddress;
	uint256 private _currentTokenId = 0;

	constructor(
		string memory _name,
		string memory _symbol,
		address _proxyRegistryAddress
	) ERC721(_name, _symbol) {
		proxyRegistryAddress = _proxyRegistryAddress;
		_initializeEIP712(_name);
	}

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
	 */
	function isApprovedForAll(address owner, address operator)
		public
		view
		override
		returns (bool)
	{
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner, operator);
	}

	/**
	 * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
	 */
	function _msgSender() internal view override returns (address sender) {
		return ContextMixin.msgSender();
	}
}
