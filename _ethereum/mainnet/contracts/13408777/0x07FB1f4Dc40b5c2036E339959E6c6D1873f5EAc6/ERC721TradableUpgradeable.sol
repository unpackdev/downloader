// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";

import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";
import "./ProxyRegistry.sol";

/**
 * @title ERC721TradableUpgradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address.
 * ERC721TradableUpgradeable is based on the opensea ERC721Tradable.
 * The openzeppelin upgradable contract is applied.
 */
abstract contract ERC721TradableUpgradeable is
  Initializable,
  NativeMetaTransaction,
  ContextMixin,
  ERC721Upgradeable
{
  address private _proxyRegistryAddress;

  function __ERC721Tradable_init(string memory name_, address proxyRegistryAddress_)
    internal
    initializer
  {
    __Context_init_unchained();
    __ERC165_init_unchained();
    _initializeEIP712(name_);
    _ERC721Tradable_init_unchained(proxyRegistryAddress_);
  }

  function _ERC721Tradable_init_unchained(address proxyRegistryAddress_) internal initializer {
    _proxyRegistryAddress = proxyRegistryAddress_;
  }

  function proxyRegistryAddress() public view virtual returns (address) {
    return _proxyRegistryAddress;
  }

  //////// The following functions are overrides required by Solidity. ////////

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  /**
   * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
   */
  function _msgSender() internal view virtual override returns (address sender) {
    return ContextMixin.msgSender();
  }

  uint256[49] private __gap;
}
