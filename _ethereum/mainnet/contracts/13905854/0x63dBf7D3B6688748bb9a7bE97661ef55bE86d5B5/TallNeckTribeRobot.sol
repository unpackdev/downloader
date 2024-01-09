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

contract TallNeckTribeRobot is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor
  (string memory customBaseURI_, address accessTokenAddress_, address proxyRegistryAddress_)
    ERC721("Tall Neck Tribe Robot", "TNTR")
  {
    customBaseURI = customBaseURI_;

    accessTokenAddress = accessTokenAddress_;

    proxyRegistryAddress = proxyRegistryAddress_;

    allowedMintCountMap[owner()] = 5;

    allowedMintCountMap[0x7b6Ada4b4DBf98205fEd6feDa1712A87504ea7b2] = 5;

    allowedMintCountMap[0xE985D0021fB166C650838D787C246B3a9e5101c6] = 5;

    allowedMintCountMap[0x94F2D2B13362f2e96A5f813150679d202B191524] = 5;

    allowedMintCountMap[0x72DF758524816BB785F144BDA2c9aCC5449EB69d] = 5;

    allowedMintCountMap[0xD7Da54Fc6Ba2d46ED00788082330A27c37842AB5] = 5;

    allowedMintCountMap[0x3e058AE6fE7B74410701175910d1e58a8C2bD5Ac] = 5;

    allowedMintCountMap[0xb156EB700dE58cfa580018136BF8e588E965Bb2a] = 5;

    allowedMintCountMap[0xcEAEE92435368cae2D9dc9Cf1156D1341847017a] = 5;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 3;

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    return a >= b ? a : b;
  }

  function allowedMintCount(address minter) public view returns (uint256) {
    if (saleIsActive) {
      return (
        max(allowedMintCountMap[minter], MINT_LIMIT_PER_WALLET) -
        mintCountMap[minter]
      );
    }

    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  address public immutable accessTokenAddress;

  uint256 public constant MAX_SUPPLY = 1000;

  uint256 public constant MAX_MULTIMINT = 3;

  uint256 public constant PRICE = 20000000000000000;

  function mint(uint256 count) public payable nonReentrant {
    if (allowedMintCount(_msgSender()) >= count) {
      updateMintCount(_msgSender(), count);
    } else {
      revert(saleIsActive ? "Minting limit exceeded" : "Sale not active");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 3 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.02 ETH per item"
    );

    ERC721 accessToken = ERC721(accessTokenAddress);

    for (uint256 i = 0; i < count; i++) {
      if (accessTokenIsActive) {
        require(
          accessToken.balanceOf(_msgSender()) > 0,
          "Access token not owned"
        );
      }

      _safeMint(_msgSender(), totalSupply());
    }
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  bool public accessTokenIsActive = true;

  function setAccessTokenIsActive(bool accessTokenIsActive_) external onlyOwner
  {
    accessTokenIsActive = accessTokenIsActive_;
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