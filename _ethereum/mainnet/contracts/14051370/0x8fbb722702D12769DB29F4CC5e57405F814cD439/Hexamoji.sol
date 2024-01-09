// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract Hexamoji is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(
    address baseFactory,
    string memory customBaseURI_,
    address proxyRegistryAddress_
  )
    ERC721Delegated(
      baseFactory,
      "Hexamoji",
      "HEXAMOJI",
      ConfigSettings({
        royaltyBps: 0,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {
    proxyRegistryAddress = proxyRegistryAddress_;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 100;

  Counters.Counter private supplyCounter;

  function mint() public nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");

    _mint(msg.sender, totalSupply());

    supplyCounter.increment();
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_tokenURI(tokenId), ".token.json"));
  }

  /** PROXY REGISTRY **/

  address private immutable proxyRegistryAddress;

  function isApprovedForAll(address owner, address operator) public view
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return _isApprovedForAll(owner, operator);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so