// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ClayLibrary.sol";
import "./ClayGen.sol";

interface IClayStorage {  
  function setStorage(uint256 id, uint128 key, uint256 value) external;
  function getStorage(uint256 id, uint128 key) external view returns (uint256);
}

interface IMudToken {  
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
}

interface IClayTraitModifier {
  function renderAttributes(uint256 _t) external view returns (string memory);
}

contract ClayStake is Ownable, ReentrancyGuard, IClayTraitModifier  {
  IClayStorage internal storageContract;
  IERC721 internal nftContract;
  IMudToken internal tokenContract;

  uint256 internal immutable startCountTime;

  uint128 public constant LAST_MUD_WITHDRAWAL = 1;

  constructor() {
    startCountTime = block.timestamp;
  }

  function setStorageContract(address _storageContract) public onlyOwner {
    storageContract = IClayStorage(_storageContract);
  }

  function setNFTContract(address _nftContract) public onlyOwner {
    nftContract = IERC721(_nftContract);
  }

  function setTokenContract(address _tokenContract) public onlyOwner {
    tokenContract = IMudToken(_tokenContract);
  } 

  function getWithdrawAmountWithTimestamp(uint256 lastMudWithdrawal, ClayLibrary.Traits memory traits) internal view returns (uint256) {
    uint256 largeOre = traits.largeOre == 1 ? 2 : 1;

    uint256 withdrawAmount = (ClayLibrary.getBaseMultiplier(traits.base) * 
      ClayLibrary.getOreMultiplier(traits.ore) * largeOre) / 1000 * 1 ether;

    uint256 stakeStartTime = lastMudWithdrawal;
    uint256 firstTimeBonus = 0;
    if(lastMudWithdrawal == 0) {
      stakeStartTime = startCountTime;
      firstTimeBonus = 100 * 1 ether;
    }

    uint256 stakingTime = block.timestamp - stakeStartTime;
    withdrawAmount *= stakingTime;
    withdrawAmount /= 1 days;
    withdrawAmount += firstTimeBonus;
    return withdrawAmount;
  }

  function getWithdrawAmount(uint256 _t) public view returns (uint256) {
    ClayLibrary.Traits memory traits = ClayLibrary.getTraits(_t);
    uint256 lastMudWithdrawal = storageContract.getStorage(_t, LAST_MUD_WITHDRAWAL);
    return getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
  }

  function getWithdrawTotal(uint256[] calldata ids) public view returns (uint256) {
    uint256 accum = 0;
    for(uint256 i = 0;i < ids.length;i++) {
      accum += getWithdrawAmount(ids[i]);
    }

    return accum;
  }

  function getWithdrawTotalWithBonus(uint256[] calldata ids, uint256 bgColorIndex) public view returns (uint256) {
    uint256 accum = 0;
    uint256 totalBonus = 1000;
    for(uint256 i = 0;i < ids.length;i++) {
      uint256 _t = ids[i];
      ClayLibrary.Traits memory traits = ClayLibrary.getTraits(_t);
      if(traits.ore < 5 && traits.bgColor == bgColorIndex) {
        totalBonus += 100;
      }
      uint256 lastMudWithdrawal = storageContract.getStorage(_t, LAST_MUD_WITHDRAWAL);
      accum += getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    }

    return accum * (totalBonus - 100) / 1000;
  }

  function withdraw(uint256 _t) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not NFT owner");
    uint256 lastMudWithdrawal = storageContract.getStorage(_t, LAST_MUD_WITHDRAWAL);
    storageContract.setStorage(_t, LAST_MUD_WITHDRAWAL, block.timestamp);
    
    ClayLibrary.Traits memory traits = ClayLibrary.getTraits(_t);
    uint256 withdrawAmount = getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    tokenContract.mint(msg.sender, withdrawAmount);
  }

  function withdrawAll(uint256[] calldata ids) public {
    uint256 totalWithdrawAmount = 0;

    for(uint256 i = 0;i < ids.length;i++) {
      require(nftContract.ownerOf(i) == msg.sender, "Not NFT owner");
      uint256 lastMudWithdrawal = storageContract.getStorage(i, LAST_MUD_WITHDRAWAL);
      storageContract.setStorage(i, LAST_MUD_WITHDRAWAL, block.timestamp);
      ClayLibrary.Traits memory traits = ClayLibrary.getTraits(i);
      totalWithdrawAmount += getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    }
    
    tokenContract.mint(msg.sender, totalWithdrawAmount);
  }

  function withdrawAllWithBonus(uint256[] calldata ids, uint256 bgColorIndex) public {
    uint256 totalWithdrawAmount = 0;
    uint256 totalBonus = 1000;

    for(uint256 i = 0;i < ids.length;i++) {
      require(nftContract.ownerOf(i) == msg.sender, "Not NFT owner");
      uint256 lastMudWithdrawal = storageContract.getStorage(i, LAST_MUD_WITHDRAWAL);
      storageContract.setStorage(i, LAST_MUD_WITHDRAWAL, block.timestamp);
      ClayLibrary.Traits memory traits = ClayLibrary.getTraits(i);
      if(traits.ore < 5 && traits.bgColor == bgColorIndex) {
        totalBonus += 100;
      }
      totalWithdrawAmount += getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    }
    
    tokenContract.mint(msg.sender, totalWithdrawAmount * (totalBonus - 100) / 1000);
  }

  function renderAttributes(uint256 _t) external view returns (string memory) {
    string memory metadataString = ClayGen.renderAttributes(_t);
    uint256 mud = getWithdrawAmount(_t);
    metadataString = string(
      abi.encodePacked(
        metadataString,
        ',{"trait_type":"Mud","value":',
        ClayLibrary.toString(mud / 1 ether),
        '}'
      )
    );

    return string(abi.encodePacked("[", metadataString, "]"));
  } 
}