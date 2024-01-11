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

contract ClayWarsV1 is Ownable, ReentrancyGuard, IClayTraitModifier  {
  IClayStorage internal storageContract;
  IERC721 internal nftContract;
  IMudToken internal tokenContract;

  string internal overrideImageUrl;

  uint256 internal immutable startCountTime = 1651553997;
  uint128 internal constant STG_LAST_MUD_WITHDRAWAL = 1;
  uint128 internal constant STG_ORE = 2;
  uint128 internal constant STG_EYES = 3;
  uint128 internal constant STG_MOUTH = 4;
  uint128 internal constant STG_LARGE_ORE = 5;
  uint128 internal constant STG_UPGRADE_CD = 6;
  uint128 internal constant STG_GEM_ULTIMATE_CD = 7;
  uint128 internal constant STG_MANIFEST_CD = 8;
  uint128 internal constant STG_NATURE_ULTIMATE_CD = 10;
  uint128 internal constant STG_SAP_CD = 11;
  uint128 internal constant STG_SELF_DESTRUCT_CD = 12;

  uint256 internal constant TRAIT_DEFAULT = 0;
  uint256 internal constant TRAIT_NO = 1;
  uint256 internal constant TRAIT_YES = 2;

  uint256 internal constant COST_EYES = 200 ether;
  uint256 internal constant COST_MOUTH = 25 ether;
  uint256 internal constant COST_LARGE_ORE = 1000 ether;

  constructor() {
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

  function getTraits(uint256 _t) internal view returns (uint8[6] memory) {
    uint8[6] memory traits = ClayGen.getTraits(_t);

    {
      uint8 ore = uint8(storageContract.getStorage(_t, STG_ORE));
      traits[ClayGen.ORE_INDEX] = ore == TRAIT_DEFAULT ? traits[ClayGen.ORE_INDEX] : ore - 1;
    }

    {
      uint8 hasEyes = uint8(storageContract.getStorage(_t, STG_EYES));
      traits[ClayGen.EYES_INDEX] = hasEyes == TRAIT_DEFAULT ? traits[ClayGen.EYES_INDEX] : hasEyes - 1;
    }

    {
      uint8 hasMouth = uint8(storageContract.getStorage(_t, STG_MOUTH));
      traits[ClayGen.MOUTH_INDEX] = hasMouth == TRAIT_DEFAULT ? traits[ClayGen.MOUTH_INDEX] : hasMouth - 1;
    }

    {
      uint8 largeOre = uint8(storageContract.getStorage(_t, STG_LARGE_ORE));
      traits[ClayGen.LARGE_ORE_INDEX] = largeOre == TRAIT_DEFAULT ? traits[ClayGen.LARGE_ORE_INDEX] : largeOre - 1;
    }

    return traits;
  }

  function getWithdrawAmountWithTimestamp(uint256 lastMudWithdrawal, uint8[6] memory traits) internal view returns (uint256) {
    uint256 largeOre = traits[ClayGen.LARGE_ORE_INDEX] == 1 ? 2 : 1;

    uint256 withdrawAmount = (ClayLibrary.getBaseMultiplier(traits[ClayGen.BASE_INDEX]) * 
      ClayLibrary.getOreMultiplier(traits[ClayGen.ORE_INDEX]) * largeOre) / 1000 * 1 ether;

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
    uint8[6] memory traits = getTraits(_t);
    uint256 lastMudWithdrawal = storageContract.getStorage(_t, STG_LAST_MUD_WITHDRAWAL);
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
      uint8[6] memory traits = getTraits(_t);
      if(traits[ClayGen.ORE_INDEX] < 5 && traits[ClayGen.BG_COLOR_INDEX] == bgColorIndex) {
        totalBonus += 100;
      }
      uint256 lastMudWithdrawal = storageContract.getStorage(_t, STG_LAST_MUD_WITHDRAWAL);
      accum += getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    }

    return accum * (totalBonus - 100) / 1000;
  }

  function withdrawToWithPenalty(uint256 _t, uint256 penalty) internal {
    uint256 lastMudWithdrawal = storageContract.getStorage(_t, STG_LAST_MUD_WITHDRAWAL);
    storageContract.setStorage(_t, STG_LAST_MUD_WITHDRAWAL, block.timestamp);
    
    uint8[6] memory traits = getTraits(_t);
    uint256 withdrawAmount = getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    tokenContract.mint(nftContract.ownerOf(_t), withdrawAmount - penalty);
  }

  function withdraw(uint256 _t) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    withdrawToWithPenalty(_t, 0);
  }

  function withdrawAll(uint256[] calldata ids) public {
    uint256 totalWithdrawAmount = 0;

    for(uint256 i = 0;i < ids.length;i++) {
      uint256 _t = ids[i];
      require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
      uint256 lastMudWithdrawal = storageContract.getStorage(_t, STG_LAST_MUD_WITHDRAWAL);
      storageContract.setStorage(_t, STG_LAST_MUD_WITHDRAWAL, block.timestamp);
      uint8[6] memory traits = getTraits(_t);
      totalWithdrawAmount += getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    }
    
    tokenContract.mint(msg.sender, totalWithdrawAmount);
  }

  function withdrawAllWithBonus(uint256[] calldata ids, uint256 bgColorIndex) public {
    uint256 totalWithdrawAmount = 0;
    uint256 totalBonus = 1000;

    for(uint256 i = 0;i < ids.length;i++) {
      uint256 _t = ids[i];
      require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
      uint256 lastMudWithdrawal = storageContract.getStorage(_t, STG_LAST_MUD_WITHDRAWAL);
      storageContract.setStorage(_t, STG_LAST_MUD_WITHDRAWAL, block.timestamp);
      uint8[6] memory traits = getTraits(_t);
      if(traits[ClayGen.ORE_INDEX] < 5 && traits[ClayGen.BG_COLOR_INDEX] == bgColorIndex) {
        totalBonus += 100;
      }
      totalWithdrawAmount += getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    }
    
    tokenContract.mint(msg.sender, totalWithdrawAmount * (totalBonus - 100) / 1000);
  }

  function renderAttributes(uint256 _t) external view returns (string memory) {
    uint8[6] memory traits = getTraits(_t);
    string memory metadataString = ClayGen.renderAttributesFromTraits(traits, _t);
    uint256 mud = getWithdrawAmount(_t);
    metadataString = string(
      abi.encodePacked(
        metadataString,
        ',{"trait_type":"Mud","value":',
        ClayLibrary.toString(mud / 1 ether),
        '}'
      )
    );

    metadataString = string(abi.encodePacked("[", metadataString, "]"));

    if(ClayLibrary.isNotEmpty(overrideImageUrl)) {
      metadataString = string(abi.encodePacked(metadataString,
        ',"image":"', overrideImageUrl, ClayLibrary.toString(_t),'"'));
    }

    return metadataString;    
  }

  function setOverrideImageUrl(string calldata _overrideImageUrl) public onlyOwner {
    overrideImageUrl = _overrideImageUrl;
  }

  function checkCoolDown(uint256 _t, uint256 cooldownTime, uint128 storageIndex, uint8[6] memory traits) internal {
    uint256 upgradeCd = storageContract.getStorage(_t, storageIndex);
    if(upgradeCd >= block.timestamp - cooldownTime) {
      uint8 hasEyes = uint8(storageContract.getStorage(_t, STG_EYES));
      hasEyes = hasEyes == TRAIT_DEFAULT ? traits[ClayGen.EYES_INDEX] : hasEyes - 1;
      if(hasEyes > 0) {        
        storageContract.setStorage(_t, STG_EYES, TRAIT_NO);
      } else {
        require(upgradeCd < block.timestamp - cooldownTime, "Cooldown");
      }
    }

    storageContract.setStorage(_t, storageIndex, block.timestamp);
  }

  // ### MARKET ###
  
  function upgradeOre(uint256 _t) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    uint256 ore = storageContract.getStorage(_t, STG_ORE);
    uint8[6] memory traits = getTraits(_t);
    uint256 oreLevel = ore == TRAIT_DEFAULT ? traits[ClayGen.ORE_INDEX] : ore - 1;
    require(oreLevel != 4 && oreLevel != 8, "oreLevel > 3");
    require(oreLevel > 0, "oreLevel == 0");
    
    checkCoolDown(_t, 1 days, STG_UPGRADE_CD, traits);

    uint256 upgradeCost = ClayLibrary.getUpgradeCost(traits[ClayGen.BASE_INDEX]) * (((oreLevel - 1) % 4) + 2) * 1 ether;

    tokenContract.burn(msg.sender, upgradeCost);
    storageContract.setStorage(_t, STG_ORE, oreLevel + 2);
  }

  function chooseOre(uint256 _t, bool pathChoice) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    uint256 ore = storageContract.getStorage(_t, STG_ORE);
    uint8[6] memory traits = getTraits(_t);
    uint256 oreLevel = ore == TRAIT_DEFAULT ? traits[ClayGen.ORE_INDEX] : ore - 1;
    require(oreLevel == 0, "oreLevel > 0");
    
    uint256 upgradeCost = ClayLibrary.getUpgradeCost(traits[ClayGen.BASE_INDEX]) * 1 ether;
    if(pathChoice) {
      upgradeCost *= 3;
    }
    
    checkCoolDown(_t, 1 days, STG_UPGRADE_CD, traits);

    uint256 newOreLevel = pathChoice ? 5 : 1;
    tokenContract.burn(msg.sender, upgradeCost);
    storageContract.setStorage(_t, STG_ORE, newOreLevel + 1);
  }

  function purchaseBinary(uint256 _t, uint128 storageIndex, uint256 traitIndex, uint256 cost) internal {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    uint256 eyes = storageContract.getStorage(_t, storageIndex);
    uint8[6] memory traits = getTraits(_t);
    require(eyes == TRAIT_NO || 
      (eyes == TRAIT_DEFAULT && traits[traitIndex] == 0), "Already have");
    
    tokenContract.burn(msg.sender, cost);
    storageContract.setStorage(_t, storageIndex, TRAIT_YES);
  }

  function purchaseEyes(uint256 _t) public nonReentrant {
    purchaseBinary(_t, STG_EYES, ClayGen.EYES_INDEX, COST_EYES);
  }

  function purchaseMouth(uint256 _t) public nonReentrant {
    purchaseBinary(_t, STG_MOUTH, ClayGen.MOUTH_INDEX, COST_MOUTH);
  } 

  function purchaseLargeOre(uint256 _t) public nonReentrant {
    purchaseBinary(_t, STG_LARGE_ORE, ClayGen.LARGE_ORE_INDEX, COST_LARGE_ORE);
  }  

  // ### ABILITIES ###

  // Downgrade another clay and earn free mud (3 day cooldown)
  function gemUltimate(uint256 _t, uint256 target) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    
    uint8[6] memory myTraits = getTraits(_t);
    uint8[6] memory targetTraits = getTraits(target);
    
    uint256 myOre = storageContract.getStorage(_t, STG_ORE);
    uint256 targetOre = storageContract.getStorage(target, STG_ORE);
    uint256 myOreLevel = myOre == TRAIT_DEFAULT ? myTraits[ClayGen.ORE_INDEX] : myOre - 1;
    uint256 targetOreLevel = targetOre == TRAIT_DEFAULT ? targetTraits[ClayGen.ORE_INDEX] : targetOre - 1;

    require(myOreLevel > 4, "Not gem");
    require(targetOreLevel != 0, "No ore");
    
    uint256 myOreLevelAdjusted = (myOreLevel - 1) % 4;
    uint256 targetOreLevelAdjusted = (targetOreLevel - 1) % 4;

    require(targetOreLevelAdjusted <= myOreLevelAdjusted, "Target > mine");
    require(targetOreLevelAdjusted != 0, "Target == 0");

    checkCoolDown(_t, 3 days, STG_GEM_ULTIMATE_CD, myTraits);

    // Check mouth    
    uint256 mouth = storageContract.getStorage(target, STG_MOUTH);
    if(mouth == TRAIT_YES || (mouth == TRAIT_DEFAULT && targetTraits[ClayGen.MOUTH_INDEX] == 1)) {
      storageContract.setStorage(target, STG_MOUTH, TRAIT_NO);
      return;
    }

    withdrawToWithPenalty(target, 0);
    // No subtraction here since = is actual -1
    storageContract.setStorage(target, STG_ORE, targetOreLevel);
    tokenContract.mint(msg.sender, 100 ether);
  }  

  // Free mouth (7 day cooldown)
  function manifest(uint256 _t) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    uint256 mouth = storageContract.getStorage(_t, STG_MOUTH);
    uint8[6] memory traits = getTraits(_t);
    require(mouth == TRAIT_NO || 
      (mouth == TRAIT_DEFAULT && traits[ClayGen.MOUTH_INDEX] == 0), "Already have");
        
    uint256 myOre = storageContract.getStorage(_t, STG_ORE);
    uint256 myOreLevel = myOre == TRAIT_DEFAULT ? traits[ClayGen.ORE_INDEX] : myOre - 1;
    require(myOreLevel > 4, "Not gem");

    checkCoolDown(_t, 7 days, STG_MANIFEST_CD, traits);

    storageContract.setStorage(_t, STG_MOUTH, TRAIT_YES);
  }  

  // Collect mud into a single clay and add 10%
  function coalesce(uint256 _t, uint256[] calldata ids) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    
    uint8[6] memory myTraits = getTraits(_t);
    uint256 myOre = storageContract.getStorage(_t, STG_ORE);
    uint256 myOreLevel = myOre == TRAIT_DEFAULT ? myTraits[ClayGen.ORE_INDEX] : myOre - 1;
    require(myOreLevel > 4, "Not gem");

    uint256 totalWithdrawAmount = 0;
    for(uint256 i = 0;i < ids.length;i++) {
      uint256 tokenId = ids[i];
      require(nftContract.ownerOf(tokenId) == msg.sender, "Not owner");
      uint256 lastMudWithdrawal = storageContract.getStorage(tokenId, STG_LAST_MUD_WITHDRAWAL);
      storageContract.setStorage(tokenId, STG_LAST_MUD_WITHDRAWAL, block.timestamp);
      uint8[6] memory traits = getTraits(tokenId);
      totalWithdrawAmount += getWithdrawAmountWithTimestamp(lastMudWithdrawal, traits);
    }
    
    tokenContract.burn(msg.sender, 20 ether);
    tokenContract.mint(msg.sender, totalWithdrawAmount * 1100 / 1000);
  }

  // Swap ore with another 1 level higher (3 day cooldown)
  function natureUltimate(uint256 _t, uint256 target) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    
    uint8[6] memory myTraits = getTraits(_t);
    uint8[6] memory targetTraits = getTraits(target);
    
    uint256 myOre = storageContract.getStorage(_t, STG_ORE);
    uint256 targetOre = storageContract.getStorage(target, STG_ORE);
    uint256 myOreLevel = myOre == TRAIT_DEFAULT ? myTraits[ClayGen.ORE_INDEX] : myOre - 1;
    uint256 targetOreLevel = targetOre == TRAIT_DEFAULT ? targetTraits[ClayGen.ORE_INDEX] : targetOre - 1;

    require(myOreLevel > 0 && myOreLevel < 5, "Not nature");
    require(targetOreLevel != 0, "No ore");
    
    uint256 myOreLevelAdjusted = (myOreLevel - 1) % 4;
    uint256 targetOreLevelAdjusted = (targetOreLevel - 1) % 4;

    require(targetOreLevelAdjusted == myOreLevelAdjusted + 1, "Target != mine + 1");

    checkCoolDown(_t, 3 days, STG_NATURE_ULTIMATE_CD, myTraits);
    tokenContract.burn(msg.sender, 50 ether);
    
    // Check mouth    
    uint256 mouth = storageContract.getStorage(target, STG_MOUTH);
    if(mouth == TRAIT_YES || (mouth == TRAIT_DEFAULT && targetTraits[ClayGen.MOUTH_INDEX] == 1)) {
      storageContract.setStorage(target, STG_MOUTH, TRAIT_NO);
      return;
    }

    withdrawToWithPenalty(target, 0);
    withdrawToWithPenalty(_t, 0);
    storageContract.setStorage(target, STG_ORE, myOreLevel + 1);
    storageContract.setStorage(_t, STG_ORE, targetOreLevel + 1);
  }  

  // Steal 25 mud (1 day cooldown)
  function sap(uint256 _t, uint256 target) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");
    
    uint8[6] memory myTraits = getTraits(_t);    
    uint256 myOre = storageContract.getStorage(_t, STG_ORE);
    uint256 myOreLevel = myOre == TRAIT_DEFAULT ? myTraits[ClayGen.ORE_INDEX] : myOre - 1;
    require(myOreLevel > 0 && myOreLevel < 5, "Not nature");    

    checkCoolDown(_t, 1 days, STG_SAP_CD, myTraits);

    withdrawToWithPenalty(target, 25 ether);
    tokenContract.mint(msg.sender, 25 ether);
  }

  // Downgrade ore level (1 day cooldown)
  function selfDestruct(uint256 _t) public nonReentrant {
    require(nftContract.ownerOf(_t) == msg.sender, "Not owner");

    uint8[6] memory myTraits = getTraits(_t);    
    uint256 myOre = storageContract.getStorage(_t, STG_ORE);
    uint256 myOreLevel = myOre == TRAIT_DEFAULT ? myTraits[ClayGen.ORE_INDEX] : myOre - 1;
    require(myOreLevel > 0 && myOreLevel < 5, "Not nature");   

    checkCoolDown(_t, 1 days, STG_SELF_DESTRUCT_CD, myTraits);

    withdrawToWithPenalty(_t, 0);
    // No subtraction here since = is actual -1
    storageContract.setStorage(_t, STG_ORE, myOreLevel);
  
    uint256 upgradeCost = ClayLibrary.getUpgradeCost(myTraits[ClayGen.BASE_INDEX]) * (((myOreLevel - 1) % 4) + 1) * 1 ether;
    tokenContract.mint(msg.sender, upgradeCost * 750 / 1000);
  }
  
  function getByOre(uint8 oreIndex, uint256 startId, uint256 endId) external view returns (uint256[] memory) {
    uint256[] memory matchingOres = new uint256[](endId - startId);
    uint256 index = 0;

    for (uint256 _t = startId; _t < endId; _t++) {
      uint8 oreTrait = ClayGen.getOreTrait(_t);
      uint256 myOre = storageContract.getStorage(_t, STG_ORE);
      uint256 myOreLevel = myOre == TRAIT_DEFAULT ? oreTrait : myOre - 1;

      if(myOreLevel == oreIndex) {
        matchingOres[index] = _t;
        index++;
      }
    }

    uint256[] memory result = new uint256[](index);
    for (uint256 i = 0; i < index; i++) {
      result[i] = matchingOres[i];
    }
    return result;
  }
}