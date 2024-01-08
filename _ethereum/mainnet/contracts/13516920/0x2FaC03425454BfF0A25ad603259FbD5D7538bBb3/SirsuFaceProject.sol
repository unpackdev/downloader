// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract SirsuFaceProject is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor (string memory customBaseURI_, address proxyRegistryAddress_)
    ERC721("SirsuFaceProject", "SIRFACE")
  {
    customBaseURI = customBaseURI_;

    proxyRegistryAddress = proxyRegistryAddress_;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 25;

  uint256 public constant PRICE = 150000000000000000;

  function mint() public payable nonReentrant {
    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");

    require(msg.value >= PRICE, "Insufficient payment, 0.15 ETH per item");

    _safeMint(_msgSender(), totalSupply());
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** PAYOUT **/

  function withdraw() public {
    uint256 balance = address(this).balance;

    payable(owner()).transfer(balance);
  }

  /** PROXY REGISTRY **/

  address private immutable proxyRegistryAddress;

  function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}

// Contract created with Studio 721 v1.0.0
// https://721.so