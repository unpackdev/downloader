// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Strings.sol";

contract BeerMugs is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  using Strings for uint256;

  constructor(address baseFactory, string memory customBaseURI_)
    ERC721Delegated(
      baseFactory,
      "2BeerMugs",
      "BM",
      ConfigSettings({
        royaltyBps: 0,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {}

  /** TOKEN PARAMETERS **/

  struct TokenParameters {
    uint256 param0;
  }

  mapping(uint256 => TokenParameters) private tokenParametersMap;

  function tokenParameters(uint256 tokenId) external view
    returns (TokenParameters memory)
  {
    return tokenParametersMap[tokenId];
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 300;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 8022;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public constant PRICE = 35000000000000004;

  Counters.Counter private supplyCounter;

  function mint(uint256 count, TokenParameters[] calldata parameters)
    public
    payable
    nonReentrant
  {
    require(saleIsActive, "Sale not active");

    if (allowedMintCount(msg.sender) >= count) {
      updateMintCount(msg.sender, count);
    } else {
      revert("Minting limit exceeded");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.035 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      uint256 id = totalSupply();

      _mint(msg.sender, id);

      tokenParametersMap[id] = parameters[i];

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_tokenURI(tokenId), ".json"));
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so