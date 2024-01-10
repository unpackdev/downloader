// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";

import "./IZensportsia.sol";

abstract contract ERC721Manageable is
  OwnableUpgradeable,
  ReentrancyGuard,
  ERC721Burnable,
  IZensportsia
{
  string private baseTokenURI;
  uint256 public constant MAX_SUPPLY_COUNT = 10000;

  SalePlans public salePlans;

  address public fundAccount;
  uint256 public presaleCount;
  uint256 public pubsaleCount;

  mapping(address => bool) public whitelists;

  bool public isMetadataPublic;

  /**
   * @notice whitelist sale validator
   * duration - 24 hours
   */
  modifier whenPresale() {
    uint256 duration = 1 days;
    require(block.timestamp >= salePlans.startTime, "PRESALE NOT STARTED");
    require(block.timestamp <= salePlans.startTime + duration, "PRESALE ENDED");
    _;
  }

  /**
   * @notice public sale starts 48 hours after presale began
   * duration - 24 hours
   */
  modifier whenPublicSale() {
    uint256 duration = 1 days;
    require(block.timestamp >= salePlans.startTime + 2 * duration, "PUBLIC SALE NOT STARTED");
    _;
  }

  function totalSupply() external pure returns (uint256) {
    return MAX_SUPPLY_COUNT;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (isMetadataPublic) {
      return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }
    return "https://ipfs.zensportsia.com/ipfs/Qmdk57rdiUqF6Ko72uEPxYy6aLabpYrErZYhrctPRV1ud9";
  }

  function revealMetadata() external onlyOwner {
    isMetadataPublic = true;
  }

  /**
   * @notice set sale plans
   */
  function setSalePlans(SalePlans memory _salePlans) public virtual onlyOwner {
    salePlans = _salePlans;
  }

  function setFundAccount(address _fundAccount) external onlyOwner {
    require(_fundAccount != address(0), "FUND ACCOUNT MUST BE VALID");
    fundAccount = _fundAccount;
  }

  function setWhitelists(address[] calldata accounts) external onlyOwner {
    for (uint256 i = 0; i < accounts.length; i++) {
      whitelists[accounts[i]] = true;
    }
  }

  function setBlacklists(address[] calldata accounts) external onlyOwner {
    for (uint256 i = 0; i < accounts.length; i++) {
      whitelists[accounts[i]] = false;
    }
  }

  function withdrawFunds() external onlyOwner {
    require(fundAccount != address(0), "Fund account not set");
    payable(fundAccount).transfer(address(this).balance);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function _setBaseURI(string memory _baseTokenURI) internal virtual {
    baseTokenURI = _baseTokenURI;
  }

  function _presaleMint(uint256 _numberOfItems) internal whenPresale {
    require(whitelists[msg.sender], "NOT A WHITELISTED ADDRESS");
    require(_numberOfItems > 0, "INVALID MINT OPERATION");
    require(presaleCount < salePlans.presaleAllocation, "PRESALE ALLOCATION LIMIT");
    require(_numberOfItems <= salePlans.limitPerMint, "TOO MANY ITEMS TO MINT");
    require(msg.value >= _numberOfItems * salePlans.mintPrice1, "INSUFFICIENT FUNDS");

    uint256 cost = 0;
    for (uint256 i = 0; i < _numberOfItems; i++) {
      if (presaleCount < salePlans.presaleAllocation) {
        presaleCount = presaleCount + 1;
        cost += salePlans.mintPrice1;
        _safeMint(msg.sender, salePlans.teamAllocation + presaleCount);
      }
    }
    uint256 remainingFund = msg.value - cost;
    if (remainingFund > 0) {
      payable(msg.sender).transfer(remainingFund);
    }
  }

  function _publicMint(uint256 _numberOfItems) internal whenPublicSale {
    require(_numberOfItems > 0, "INVALID MINT OPERATION");
    require(_numberOfItems <= salePlans.limitPerMint, "TOO MANY ITEMS TO MINT");
    require(msg.value >= _numberOfItems * salePlans.mintPrice2, "INSUFFICIENT FUNDS");

    uint256 cost = 0;
    for (uint256 i = 0; i < _numberOfItems; i++) {
      if (salePlans.teamAllocation + presaleCount + pubsaleCount < MAX_SUPPLY_COUNT) {
        pubsaleCount = pubsaleCount + 1;
        cost += salePlans.mintPrice2;
        _safeMint(msg.sender, salePlans.teamAllocation + presaleCount + pubsaleCount);
      }
    }
    uint256 remainingFund = msg.value - cost;
    if (remainingFund > 0) {
      payable(msg.sender).transfer(remainingFund);
    }
  }
}
