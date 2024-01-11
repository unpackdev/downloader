// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract RektGarageConcoursdElegance is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  string private customBaseURI;
  string private customContractURI;
  bool public saleIsActive = true;

  constructor(string memory _customBaseURI, string memory _customContractURI, address _proxyRegistryAddress) ERC721( "RektGarageConcoursdElegance", "RGCdE" ) {
    customBaseURI = _customBaseURI;
    customContractURI = _customContractURI;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  uint256 public constant MAX_SUPPLY = 100;
  Counters.Counter private supplyCounter;

  function mint(uint256 count) public nonReentrant onlyOwner {
    require(saleIsActive, "Sale not active");
    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");
    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());
      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  function setSaleIsActive(bool _saleIsActive) external onlyOwner {
    saleIsActive = _saleIsActive;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }
  function setBaseURI(string memory _customBaseURI) external onlyOwner {
    customBaseURI = _customBaseURI;
  }

  function setContractURI(string memory _customContractURI) external onlyOwner {
    customContractURI = _customContractURI;
  }
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