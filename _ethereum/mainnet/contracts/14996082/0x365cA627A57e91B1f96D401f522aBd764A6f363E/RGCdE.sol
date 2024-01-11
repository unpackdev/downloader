// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract RektGarageConcoursdElegance is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor(string memory customBaseURI_, address proxyRegistryAddress_) ERC721( "Rekt Garage Concours dElegance", "RGCdE" ) {
    customBaseURI = customBaseURI_;
    proxyRegistryAddress = proxyRegistryAddress_;
  }

  uint256 public constant MAX_SUPPLY = 100;
  uint256 public constant MAX_MULTIMINT = 100;

  function mint(uint256 count) public nonReentrant onlyOwner {
    require(saleIsActive, "Sale not active");
    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");
    require(count <= MAX_MULTIMINT, "Mint at most 100 at a time");
    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());
    }
  }

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  string private customBaseURI;
  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }
  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  string private customContractURI = "https://rektgarage.xyz/metadata/RGCdE/";
  function contractURI() public view returns (string memory) {
    return customContractURI;
  }

  function withdraw() public nonReentrant onlyOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(owner()), balance);
  }

  address private immutable proxyRegistryAddress;
  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

}