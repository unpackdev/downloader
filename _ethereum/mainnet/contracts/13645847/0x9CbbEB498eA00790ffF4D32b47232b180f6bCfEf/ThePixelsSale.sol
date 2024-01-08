// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !! Modified version of uwucrew sale contract !!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

import "./IThePixels.sol";

interface ITheDudes {
  function tokensOfOwner(address _owner) external view returns (uint256[] memory);
}

contract ThePixelsSale is Ownable, ReentrancyGuard {
  address public nftAddress;
  address public theDudesAddress;
  address public creatorAddress;

  bool public isMintingActive;
  bool public isWLActive; //WL for the dudes owners;
  bool public isSaleActive;
  uint256 public amountForSale;
  uint256 public ticketCount;

  uint256 public buyPrice = 0.06 ether;

  uint256 public saleStartTime;
  uint256 public constant waveLength = 300; //5 mins

  mapping(uint256 => mapping(address => bool)) public waveLock;
  mapping(address => uint256) public balance;
  mapping(uint256 => bool) public usedTheDudesTokenIds;

  event Reserved(address sender, uint256 count);
  event Minted(address sender, uint256 count);

  constructor(
    address _nftAddress,
    address _theDudesAddress,
    address _creatorAddress,
    uint256 _amountForSale
  ) Ownable() ReentrancyGuard() {
    nftAddress = _nftAddress;
    theDudesAddress = _theDudesAddress;
    creatorAddress = _creatorAddress;
    amountForSale = _amountForSale;
    //Give 1 to the creator
    ticketCount += 1;
    balance[creatorAddress] = 1;
  }

  function startSale() external onlyOwner {
    saleStartTime = block.timestamp;
    isSaleActive = true;
  }

  function setIsSaleActive(bool _isSaleActive) external onlyOwner {
    isSaleActive = _isSaleActive;
  }

  function setIsWLActive(bool _isWLActive) external onlyOwner {
    isWLActive = _isWLActive;
  }

  function setIsMintingActive(bool _isMintingActive) external onlyOwner {
    isMintingActive = _isMintingActive;
  }

  function setNFTAddress(address _nftAddress) external onlyOwner {
    nftAddress = _nftAddress;
  }

  function withdrawETH() external onlyOwner {
    payable(creatorAddress).transfer(address(this).balance);
  }

  function claimableTheDudesTickets(address _owner) public view returns (uint256) {
    uint256[] memory tokenIds = ITheDudes(theDudesAddress).tokensOfOwner(_owner);
    uint256 count = 0;
    for (uint256 i=0; i<tokenIds.length; i++) {
      if (!usedTheDudesTokenIds[tokenIds[i]]) {
        count++;
      }
    }
    return count;
  }

  function buyTicketsWithTheDudes(address _owner, uint256 count) external payable nonReentrant {
    require(isWLActive, "WL is not active yet");
    require(count > 0, "Invalid count");
    require(ticketCount < amountForSale, "Sold out! Sorry!");
    require(msg.value == count * buyPrice, "Invalid ETH amount");
    require(claimableTheDudesTickets(_owner) >= count, "Not enough the dudes");

    uint256[] memory tokenIds = ITheDudes(theDudesAddress).tokensOfOwner(_owner);
    uint256 claimCount = 0;
    for (uint256 i=0; i<tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (!usedTheDudesTokenIds[tokenId]) {
        usedTheDudesTokenIds[tokenId] = true;
        claimCount++;
        if (claimCount == count) {
          break;
        }
      }
    }

    ticketCount += claimCount;
    balance[msg.sender] += claimCount;
  }

  function buyTickets(uint256 count) external payable nonReentrant {
    require(isSaleActive, "Sale is not active yet");
    require(count > 0, "Invalid count");
    require(ticketCount < amountForSale, "Sold out! Sorry!");

    uint256 wave = getWave();

    require(!waveLock[wave][msg.sender], "Locked for this wave");
    require(count <= maxPerTX(wave), "Max for TX in this wave");
    require(msg.value == count * buyPrice, "Invalid ETH amount");

    uint256 ethAmountOwed;
    if (ticketCount + count > amountForSale) {
      uint256 amountRemaining = amountForSale-ticketCount;
      ethAmountOwed = buyPrice * (count-amountRemaining);
      count = amountRemaining;
    }

    // Update the amount the person is eligible for minting.
    ticketCount += count;
    balance[msg.sender] += count;
    // Lock this address for the phase.
    waveLock[wave][msg.sender] = true;

    emit Reserved(msg.sender, count);

    if (ethAmountOwed > 0) {
      (bool success, ) = msg.sender.call{ value: ethAmountOwed }("");
      require(success, "Address: unable to send value, recipient may have reverted");
    }
  }

  function mint(uint256 count, uint256[] memory salts) public {
    require(isMintingActive, "Minting is not active yet");
    require(salts.length == count);
    _mint(msg.sender, count, salts);
  }

  function forceMint(address account, uint256 count, uint256[] memory salts) public onlyOwner {
    _mint(account, count, salts);
  }

  function _mint(address account, uint256 count, uint256[] memory salts) internal {
    require(count > 0, "Invalid count");
    require(count <= balance[account], "Not enough balance");
    balance[account] -= count;

    for (uint256 i = 0; i < count; i++) {
      IThePixels(nftAddress).mint(account, salts[i], i);
    }

    emit Minted(account, count);
  }

  function currentMaxPerTX() external view returns (uint256) {
    return maxPerTX(getWave());
  }

  function maxPerTX(uint256 _wave) public pure returns (uint256) {
    if (_wave == 0) {
      return 2;
    } else if (_wave == 1) {
      return 4;
    } else if (_wave == 2) {
      return 8;
    } else {
      return 10;
    }
  }

  function getWave() public view returns (uint256) {
    uint256 timespanSinceStart = block.timestamp - saleStartTime;
    return timespanSinceStart/waveLength;
  }
}
