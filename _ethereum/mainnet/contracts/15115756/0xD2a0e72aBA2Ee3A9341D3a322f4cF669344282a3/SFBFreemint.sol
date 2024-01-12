// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract SoulFoodBrotherAndSister is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  constructor(string memory customBaseURI_)
    ERC721("Hot Pop Soul Drop", "HotPop")
  {
    customBaseURI = customBaseURI_;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 40;

  uint256 public constant MAX_MULTIMINT = 20;

  Counters.Counter private supplyCounter;

  mapping(address => uint8) private whitelist;

function mint(uint256 count) public nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

function whitelistMint(uint256 count) public nonReentrant {
    require(whiteListMintEnabled, " White List Sale not active");
    require(count <= whitelist[msg.sender], "Not on whitelist");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function NumOfWhiteListMints(address addr) external view returns (uint8) {
    return whitelist[addr];
  }


function setWhitelist(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = numAllowedToMint;
    }
  }





  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }



  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }
  
  bool public whiteListMintEnabled = false;
  
  function setWhiteListMintEnabled(bool whiteListMintEnabled_) external onlyOwner {
    whiteListMintEnabled = whiteListMintEnabled_;
  }
  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override(ERC721) returns (string memory) {
    return customBaseURI;
  }


}

