// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract TallNeckTribe is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor (string memory customBaseURI_, address proxyRegistryAddress_)
    ERC721("Tall Neck Tribe", "TNT")
  {
    customBaseURI = customBaseURI_;

    proxyRegistryAddress = proxyRegistryAddress_;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 20;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 2000;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public constant PRICE = 60000000000000000;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    if (allowedMintCount(_msgSender()) >= count) {
      updateMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.06 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      _safeMint(_msgSender(), totalSupply());
    }
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  mapping(uint256 => string) private tokenURIMap;

  function setTokenURI(uint256 tokenId, string memory tokenURI_)
    external
    onlyOwner
  {
    tokenURIMap[tokenId] = tokenURI_;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    string memory tokenURI_ = tokenURIMap[tokenId];

    if (bytes(tokenURI_).length > 0) {
      return tokenURI_;
    }

    return string(abi.encodePacked(super.tokenURI(tokenId)));
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance);
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

// Contract created with Studio 721 v1.4.0
// https://721.so