// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./ERC721.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract OpenSeaWhitelistERC721 is ERC721 {
  address public constant proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

  constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

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
}
