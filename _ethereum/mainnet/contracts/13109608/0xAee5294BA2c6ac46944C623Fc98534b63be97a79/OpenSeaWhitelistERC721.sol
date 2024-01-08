// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract OpenSeaWhitelistERC721 is ERC721, ContextMixin, NativeMetaTransaction, Ownable() {
  address public constant proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

  constructor(string memory name_, string memory symbol_)
    ERC721(name_, symbol_)
    NativeMetaTransaction(name_)
    {}

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
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
  function _msgSender() internal view override returns (address payable) {
    return ContextMixin.msgSender();
  }
}
