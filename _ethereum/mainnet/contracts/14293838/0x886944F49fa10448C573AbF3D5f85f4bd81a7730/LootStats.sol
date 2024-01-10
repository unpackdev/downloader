// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
/*
LootStats.sol
Lootverse Utility contract to gather stats for Loot (For Adventurers) Bags, Genesis Adventurers and other "bag" like contracts.

See OG Loot Contract for lists of all possible items.
https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7

All functions are made public incase they are useful but the expected use is through the main
4 stats functions:

- getGreatness()
- getLevel()
- getRating()
- getNumberOfItemsInClass()
- getGreatnessByItem()
- getLevelByItem()
- getRatingByItem()
- getClassByItem()

Each of these take a Loot Bag ID.  This contract relies and stores the most current LootClassification contract.

The LootStats(_TBD_) contract can be used to get "bag" level stats for Loot bag's tokenID.

So a typical use might be:

// get stats for loot bag# 1234
{
    LootStats stats = 
        LootStats(_TBD_);

    uint256 level = stats.getLevel(1234);
    uint256 greatness = stats.getGreatness(1234);
    uint256 rating = stats.getRating(1234);
    uint256 level = stats.getLevel([1234,1234,1234,1234,1234,1234,1234,1234]);
    uint256 greatness = stats.getGreatness([1234,1234,1234,1234,1234,1234,1234,1234]);
    uint256 rating = stats.getRating([1234,1234,1234,1234,1234,1234,1234,1234]);


}
*/
interface ILootClassification {
    enum Type
    {
        Weapon,
        Chest,
        Head,
        Waist,
        Foot,
        Hand,
        Neck,
        Ring
    }
    enum Class
    {
        Warrior,
        Hunter,
        Mage,
        Any
    }
    function getLevel(Type lootType, uint256 index) external pure returns (uint256);
    function getClass(Type lootType, uint256 index) external pure returns (Class);
    function weaponComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function chestComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function headComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function waistComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function footComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function handComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function ringComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function neckComponents(uint256 tokenId) external pure returns (uint256[6] memory);
}

contract LootStats is Ownable
{
    ILootClassification private lootClassification;    
    address public lootClassificationAddress;
    ILootClassification.Type[8] private itemTypes = [ILootClassification.Type.Weapon, ILootClassification.Type.Chest, ILootClassification.Type.Head, ILootClassification.Type.Waist, ILootClassification.Type.Foot, ILootClassification.Type.Hand, ILootClassification.Type.Neck, ILootClassification.Type.Ring];

    constructor(address lootClassification_) {
        lootClassificationAddress = lootClassification_;
        lootClassification = ILootClassification(lootClassificationAddress);
    }

    function setLootClassification(address lootClassification_) public onlyOwner {
        lootClassificationAddress = lootClassification_;
        lootClassification = ILootClassification(lootClassificationAddress);
    }

    function getLevel(uint256 tokenId) public view returns (uint256)
    {
        return getLevel([tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId]);
    }

    function getLevel(uint256[8] memory tokenId) public view returns (uint256)
    {
        uint256 level;
        for(uint8 i=0; i < itemTypes.length; i++) {
            if (tokenId[i] == 0) 
                level += 1;
            else
                level += getLevelByItem(itemTypes[i], tokenId[i]);    
        }     
    
        return level;
    }

    function getGreatness(uint256 tokenId) public view returns (uint256)
    {
        return getGreatness([tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId]);
    }

    function getGreatness(uint256[8] memory tokenId) public view returns (uint256)
    {
        uint256 greatness;
        for(uint8 i=0; i < itemTypes.length; i++) {
            if (tokenId[i] == 0) 
                greatness += 15;
            else
                greatness += getGreatnessByItem(itemTypes[i], tokenId[i]);    
        }

        return greatness;
    }

    function getRating(uint256 tokenId) public view returns (uint256)
    {   
        return getRating([tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId]);
    }

    function getRating(uint256[8] memory tokenId) public view returns (uint256)
    {   
        uint256 rating;
        for(uint8 i=0; i < itemTypes.length; i++) {
            if (tokenId[i] == 0) 
                rating += 15;
            else
                rating += getRatingByItem(itemTypes[i], tokenId[i]);    
        }

        return rating;
    }

    function getNumberOfItemsInClass(ILootClassification.Class classType, uint256 tokenId) public view returns (uint256)
    {   
        return getNumberOfItemsInClass(classType, [tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId]);
    }

    function getNumberOfItemsInClass(ILootClassification.Class classType, uint256[8] memory tokenId) public view returns (uint256)
    {   
        uint256 count;
        for(uint8 i=0; i < itemTypes.length; i++) {
            if (classType == getClassByItem(itemTypes[i], tokenId[i])) {
                count++;
            }   
        }
        return count;
    }

    function getGreatnessByItem(ILootClassification.Type lootType, uint256 tokenId) 
        public view returns (uint256) 
    {        
        return _getComponent(5, lootType, tokenId);
    }

    function getLevelByItem(ILootClassification.Type lootType, uint256 tokenId)
        public view returns (uint256) 
    {
        return lootClassification.getLevel(lootType, _getComponent(0, lootType, tokenId));
    }

    function getRatingByItem(ILootClassification.Type lootType, uint256 tokenId) 
        public view returns (uint256)
    {   
        return getLevelByItem(lootType, tokenId) * getGreatnessByItem(lootType, tokenId);
    }

    function getClassByItem(ILootClassification.Type lootType, uint256 tokenId) 
        public view returns (ILootClassification.Class) 
    {
        return lootClassification.getClass(lootType, _getComponent(0, lootType, tokenId));
    }
    function _getComponent(uint256 componentId, ILootClassification.Type lootType, uint256 tokenId)
        internal view returns (uint256)
    {
        if (lootType == ILootClassification.Type.Weapon) {
            return lootClassification.weaponComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Chest) {
            return lootClassification.chestComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Head) {
            return lootClassification.headComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Waist) {
            return lootClassification.waistComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Foot) {
            return lootClassification.footComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Hand) {
            return lootClassification.handComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Ring) {
            return lootClassification.ringComponents(tokenId)[componentId];
        } else {
            return lootClassification.neckComponents(tokenId)[componentId];
        }
    }
}