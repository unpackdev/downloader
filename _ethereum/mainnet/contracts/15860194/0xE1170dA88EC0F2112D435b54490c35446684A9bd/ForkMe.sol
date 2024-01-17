// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";

interface Forkers {
    function getAttributePointsFor(address _address) external view returns (uint64);
    function spendAttributePoints(address _address) external;
    function DIEFORKER(uint256 token) external;
}

contract Forked is Ownable, ReentrancyGuard {

    event TraitAdded(TRAIT_TYPE traitType, uint64 cost, uint8 id, uint16 powerLevel);
    event ForkerBurned(uint256 token, uint64 points, address burner);
    event ForkerUpgraded(uint256 token);
    event yumyum(uint256 goblin, uint256 token, uint16 powerLevel, uint64 burnValue);
    event HerLight(uint256 wagdie, uint256 token, uint16 powerLevel, uint64 burnValue);

    error InvalidTrait(TRAIT_TYPE traitType, uint8 id);

    enum TRAIT_TYPE { BACKGROUND, BACK, FEET, SKIN, HEAD, ARMS, EXTRA, EXTRA2, EXTRA3 }

    address public forkerAddress = 0xb0EdA4f836aF0F8Ca667700c42fcEFA0742ae2B5;
    address public GOBLIN_TOWN_CONTRACT = 0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e;
    address public WAGDIE_CONTRACT = 0x659A4BdaAaCc62d2bd9Cb18225D9C89b5B697A5A;

    uint8 public maxExtremelyRares = 5;
    uint64 public extremelyRareCost = 500;
    uint16 public maxPowerLevelToBurn = 10;
    uint16 public burnStage = 0;
    
    bool public hungryGoblins = false;
    bool public herLightIsLow = false;

    mapping(uint256 => TokenData) private tokenToData;
    mapping(address => uint64) private attributePoints;
    mapping(TRAIT_TYPE => mapping(uint8 => TraitData)) public traitData;
    mapping(uint8 => bool) public extremelyRareClaimed;
    mapping(uint256 => mapping(uint256 => bool)) public hasGoblinAte;
    mapping(uint256 => mapping(uint256 => bool)) public hasWagdieBurnt;
    
    struct TraitData {
        uint16 powerLevel;
        uint64 cost;
    }

    struct TokenData {
        uint8 background;
        uint8 back;
        uint8 feet;
        uint8 skin;
        uint8 head;
        uint8 arms;
        uint8 extra;
        uint8 extra2;
        uint8 extra3;
        uint8 extremelyRare;
        bool usedBasePoints;
        uint64 pointsSpent;
        uint16 powerLevel;
    }

    constructor() {

        addTrait(TRAIT_TYPE.BACKGROUND, 0, 0, 0);
        addTrait(TRAIT_TYPE.BACKGROUND, 1, 5, 15);
        addTrait(TRAIT_TYPE.BACKGROUND, 2, 10, 35);
        
        addTrait(TRAIT_TYPE.BACK, 0, 0, 0);
        addTrait(TRAIT_TYPE.BACK, 1, 5, 15);
        addTrait(TRAIT_TYPE.BACK, 2, 8, 35);
        addTrait(TRAIT_TYPE.BACK, 3, 15, 80);
        addTrait(TRAIT_TYPE.BACK, 4, 25, 150);
        addTrait(TRAIT_TYPE.BACK, 5, 40, 350);
        addTrait(TRAIT_TYPE.BACK, 6, 75, 475);
        addTrait(TRAIT_TYPE.BACK, 7, 125, 1000);

        addTrait(TRAIT_TYPE.FEET, 0, 0, 0);
        addTrait(TRAIT_TYPE.FEET, 1, 5, 20);
        addTrait(TRAIT_TYPE.FEET, 2, 20, 175);
        addTrait(TRAIT_TYPE.FEET, 3, 75, 250);
        
        addTrait(TRAIT_TYPE.SKIN, 0, 0, 0);
        addTrait(TRAIT_TYPE.SKIN, 1, 5, 50);
        addTrait(TRAIT_TYPE.SKIN, 2, 10, 100);
        addTrait(TRAIT_TYPE.SKIN, 3, 40, 350);
        addTrait(TRAIT_TYPE.SKIN, 4, 60, 750);
        addTrait(TRAIT_TYPE.SKIN, 5, 120, 1500);
        addTrait(TRAIT_TYPE.SKIN, 6, 200, 2500);

        addTrait(TRAIT_TYPE.HEAD, 0, 0, 0);
        addTrait(TRAIT_TYPE.HEAD, 1, 5, 30);
        addTrait(TRAIT_TYPE.HEAD, 2, 15, 80);
        addTrait(TRAIT_TYPE.HEAD, 3, 20, 200);
        addTrait(TRAIT_TYPE.HEAD, 4, 35, 400);
        addTrait(TRAIT_TYPE.HEAD, 5, 50, 600);
        addTrait(TRAIT_TYPE.HEAD, 6, 70, 800);
        addTrait(TRAIT_TYPE.HEAD, 7, 100, 1000);
        addTrait(TRAIT_TYPE.HEAD, 8, 125, 1400);
        addTrait(TRAIT_TYPE.HEAD, 9, 150, 2000);
        addTrait(TRAIT_TYPE.HEAD, 10, 200, 2500);

        addTrait(TRAIT_TYPE.ARMS, 0, 0, 0);
        addTrait(TRAIT_TYPE.ARMS, 1, 5, 10);
        addTrait(TRAIT_TYPE.ARMS, 2, 10, 30);
        addTrait(TRAIT_TYPE.ARMS, 3, 15, 50);
        addTrait(TRAIT_TYPE.ARMS, 4, 25, 100);
        
        
    }

    function buyTraits(uint256 token, TRAIT_TYPE[] calldata traitTypes, uint8[] calldata traitIds) public nonReentrant {
        require(IERC721(forkerAddress).ownerOf(token) == msg.sender, "Not owner");
        require(traitTypes.length == traitIds.length, "Inputs invalid");

        TokenData storage tokenData = tokenToData[token];

        require(tokenData.extremelyRare == 0, "Can't upgrade a 1/1");

        uint64 toSpend = 0;
        uint16 newPowerLevel = tokenData.powerLevel;

        for(uint i = 0; i < traitTypes.length; i++) {
            uint64 spent = 0;
            uint16 newPower = 0;

            (spent, newPower) = _changeTokenTrait(traitTypes[i], traitIds[i], tokenData, newPowerLevel);

            newPowerLevel = newPower;
            toSpend += spent;
        }

        _claimBasePoints(tokenData);
        
        _spendAttributePoints(msg.sender, toSpend);

        tokenData.pointsSpent += toSpend;
        tokenData.powerLevel = newPowerLevel;

        emit ForkerUpgraded(token);

    }

    function _claimBasePoints(TokenData storage data) internal {
        if(data.usedBasePoints == false) {
            data.usedBasePoints = true;

            attributePoints[msg.sender] += 5;
        }
    }

    function buyExtremelyRare(uint256 token, uint8 trait) public nonReentrant {
        require(IERC721(forkerAddress).ownerOf(token) == msg.sender, "Not owner");
        require(trait != 0 && trait <= maxExtremelyRares, "Invalid input");
        require(!extremelyRareClaimed[trait], "Already claimed");

        TokenData storage tokenData = tokenToData[token];

        require(tokenData.extremelyRare == 0, "Already rare");

        _claimBasePoints(tokenData);

        _spendAttributePoints(msg.sender, extremelyRareCost);

        extremelyRareClaimed[trait] = true;
        tokenData.extremelyRare = trait;
        tokenData.pointsSpent += extremelyRareCost;

        tokenData.powerLevel = 50000;

        extremelyRareCost += 200;

        emit ForkerUpgraded(token);

    }

    function burnForkers(uint256[] calldata tokens) public nonReentrant {
        uint64 attributeReward = 0;

        for(uint i = 0; i < tokens.length; i++)
            attributeReward += _burnForker(tokens[i]);

        attributePoints[msg.sender] += attributeReward;
    }

    function getTokenData(uint256 token) external view returns (TokenData memory tokenData) {
        return tokenToData[token];
    }

    function getAttributeData(address _address) external view returns (uint64) {
        uint64 refPoints = Forkers(forkerAddress).getAttributePointsFor(_address);

        return attributePoints[_address] + refPoints;
    }

    function _burnForker(uint256 token) internal returns (uint64) {
        require(IERC721(forkerAddress).ownerOf(token) == msg.sender, "Not owner");
        
        Forkers(forkerAddress).DIEFORKER(token);

        TokenData memory tokenData = tokenToData[token];

        require(tokenData.extremelyRare == 0, "Can't burn 1/1");
        
        uint64 attributeReward = tokenData.pointsSpent + 5;

        if(!tokenData.usedBasePoints) attributeReward += 5;

        emit ForkerBurned(token, attributeReward, msg.sender);

        return attributeReward;
    }

    function getExtremelyRares() external view returns (bool[] memory, uint64 cost) {
        bool[] memory rares = new bool[] (maxExtremelyRares);

        for(uint8 i = 0; i < maxExtremelyRares; i++) {
            uint8 trait = i + 1;
            bool claimed = extremelyRareClaimed[trait];

            rares[i] = claimed;
        }

        return (rares, extremelyRareCost);
    }

    function _getAttributePoints(address _address) internal returns (uint64) {
        //Grab owed attribute points from referral system.
        uint64 refPoints = Forkers(forkerAddress).getAttributePointsFor(_address);

        //If any exist remove and add to this contract.
        if(refPoints > 0) {
            Forkers(forkerAddress).spendAttributePoints(_address);
            attributePoints[_address] += refPoints;
        }

        return attributePoints[_address];
    }

    function _spendAttributePoints(address _address, uint64 amount) internal {
        uint64 myPoints = _getAttributePoints(_address);
        require(myPoints >= amount, "Not enough points");

        attributePoints[_address] -= amount;
    }

    function yummyyummy(uint256 goblin, uint256 forker) public nonReentrant {
        require(IERC721(GOBLIN_TOWN_CONTRACT).ownerOf(goblin) == msg.sender, "u dont tell me wat to do");
        require(!hasGoblinAte[burnStage][goblin], "me full");
        require(hungryGoblins, "not hungry right now");
        hasGoblinAte[burnStage][goblin] = true;
        require(!_isForkerProtected(forker), "Forker is protected");

        TokenData memory data = tokenToData[forker];

        require(data.powerLevel <= maxPowerLevelToBurn, "dis not fit in mouth");
        Forkers(forkerAddress).DIEFORKER(forker);

        uint64 howtastey = data.pointsSpent + (!data.usedBasePoints ? 5 : 0);

        attributePoints[msg.sender] += howtastey;

        emit yumyum(goblin, forker, data.powerLevel, howtastey);
    }

    function herLight(uint256 wagdie, uint256 forker) public nonReentrant {
        require(IERC721(WAGDIE_CONTRACT).ownerOf(wagdie) == msg.sender, /* 𝕴 𝖉𝖔 𝖓𝖔𝖙 𝖑𝖎𝖘𝖙𝖊𝖓 𝖙𝖔 𝖞𝖔𝖚 */ "Not owner");
        require(!hasWagdieBurnt[burnStage][wagdie], /* 𝕴 𝖍𝖆𝖛𝖊 𝖉𝖔𝖓𝖊 𝖊𝖓𝖔𝖚𝖌𝖍 𝖋𝖔𝖗 𝖍𝖊𝖗 𝖑𝖎𝖌𝖍𝖙 */ "Already burnt");
        require(herLightIsLow, /* 𝕳𝖊𝖗 𝖑𝖎𝖌𝖍𝖙 𝖎𝖘 𝖌𝖑𝖔𝖜𝖎𝖓𝖌 𝖘𝖙𝖗𝖔𝖓𝖌 */ "Not yet");
        hasWagdieBurnt[burnStage][wagdie] = true;
        require(!_isForkerProtected(forker), "Forker is protected");

        TokenData memory data = tokenToData[forker];

        require(data.powerLevel <= maxPowerLevelToBurn, /* 𝕴 𝖈𝖆𝖓𝖓𝖔𝖙 𝖈𝖆𝖙𝖈𝖍 𝖘𝖚𝖈𝖍 𝖆 𝖕𝖔𝖜𝖊𝖗𝖋𝖚𝖑 𝖈𝖗𝖊𝖆𝖙𝖚𝖗𝖊 */ "Too powerful");
        Forkers(forkerAddress).DIEFORKER(forker);

        uint64 howHot = data.pointsSpent + (!data.usedBasePoints ? 5 : 0);

        attributePoints[msg.sender] += howHot;

        emit HerLight(wagdie, forker, data.powerLevel, howHot);
    }


    function _changeTokenTrait(TRAIT_TYPE traitType, uint8 traitId, TokenData storage tokenData, uint16 currentPLevel) internal returns (uint64, uint16) {
        TraitData memory traitD = traitData[traitType][traitId];
        uint64 cost = traitD.cost;

        //Trait doesn't exist.
        if(cost == 0) revert InvalidTrait(traitType, traitId);

        if(traitType == TRAIT_TYPE.BACKGROUND) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.background].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.background = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.BACK) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.back].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.back = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.FEET) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.feet].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.feet = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.SKIN) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.skin].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.skin = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.HEAD) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.head].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.head = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.ARMS) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.arms].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.arms = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.EXTRA) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.extra].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.extra = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.EXTRA2) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.extra2].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.extra2 = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.EXTRA3) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.extra3].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.extra3 = traitId;
            return (cost, newPowerLevel);
        }

        return (cost, currentPLevel);
    }

    function _isForkerProtected(uint256 forker) public view returns (bool) {
        return IERC721(forkerAddress).ownerOf(forker) == owner();
    }

    function addTrait(TRAIT_TYPE traitType, uint8 traitId, uint64 cost, uint16 level) public onlyOwner {
        TraitData storage traitD = traitData[traitType][traitId];

        traitD.cost = cost;
        traitD.powerLevel = level;

        emit TraitAdded(traitType, cost, traitId, level);
    }

    function addAttributePoints() public onlyOwner {
        attributePoints[msg.sender] += 10000;
    }

    function setForkerAddress(address _address) public onlyOwner {
        forkerAddress = _address;
    }

    function setExtremelyRareData(uint64 cost, uint8 maxExtremely) public onlyOwner {
        extremelyRareCost = cost;
        maxExtremelyRares = maxExtremely;
    }

    function setGoblinTownAddress(address _address) public onlyOwner {
        GOBLIN_TOWN_CONTRACT = _address;
    }

    function setWagdieAddress(address _address) public onlyOwner {
        WAGDIE_CONTRACT = _address;
    }

    function incrementBurnStage() public onlyOwner {
        burnStage++;
    }

    function setBurnMechanics(bool _hungryGoblins, bool _lowLight) public onlyOwner {
        herLightIsLow = _lowLight;
        hungryGoblins = _hungryGoblins;
    }

    function setMaxPowerLevelForBurn(uint16 power) public onlyOwner {
        maxPowerLevelToBurn = power;
    }

    function adminGiveAttributePoints(address[] calldata addresses, uint64[] calldata points) public onlyOwner {

        for(uint i = 0; i < addresses.length; i++)
            attributePoints[addresses[i]] += points[i];
            
    }
}