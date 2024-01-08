// SPDX-License-Identifier: MIT
// Galaxy Heroes NFT game )
pragma solidity ^0.8.6;

import "HeroesUpgraderV2.sol";


contract HeroesUpgraderV3  is HeroesUpgraderV2 {

    bool public writeToExternal;

    
    function upgrade(uint256 oldHero, address modifierContract, uint256 modifierId) public override{
        super.upgrade(oldHero, modifierContract, modifierId);
        if (writeToExternal) {
            //get tokenId of token thet will mint
            uint256 justMintedToken = IHero(
                enabledModifications[modifierContract][modifierId].destinitionContract
            ).totalSupply() - 1;
            uint256[] memory tokens = new uint256[](2);
            uint8[] memory rarities = new uint8[](2);
            tokens[0] = oldHero;
            tokens[1] = justMintedToken;
            rarities[0] = uint8(Rarity.SimpleUpgraded);
            rarities[1] = uint8(enabledModifications[modifierContract][modifierId].destinitionRarity); 

            IRarity(externalStorage).loadRaritiesBatch(
                enabledModifications[modifierContract][modifierId].sourceContract, // Heroes
                tokens,
                rarities
            );
        }

    }

    function upgradeBatch(uint256[] memory oldHeroes, address modifierContract, uint256 modifierId) public override {
        require(oldHeroes.length <= 10, "Not more then 10");
        for (uint256 i; i < oldHeroes.length; i ++) {
            upgrade(oldHeroes[i], modifierContract, modifierId);
        }
    }

    
    //////////////////////////////////////////////////////
    ///   Admin Functions                             ////
    //////////////////////////////////////////////////////

    function setWriteToExternal(bool _write) external onlyOwner {
        writeToExternal = _write;
    }
}
