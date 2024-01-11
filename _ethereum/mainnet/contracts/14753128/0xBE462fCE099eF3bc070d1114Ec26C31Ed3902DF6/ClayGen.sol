// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ClayLibrary.sol";

library ClayGen {  
  struct Trait {
    string traitType;
    string traitName;
  }

  function getTiers() internal pure returns (uint16[][6] memory) {
    uint16[][6] memory TIERS = [
      new uint16[](4),
      new uint16[](9),
      new uint16[](2),
      new uint16[](2),
      new uint16[](6),
      new uint16[](2)      
    ];

    //Base
    TIERS[0][0] = 4000;
    TIERS[0][1] = 3000;
    TIERS[0][2] = 2000;
    TIERS[0][3] = 1000;

    //Ore
    TIERS[1][0] = 5000;
    TIERS[1][1] = 1500;
    TIERS[1][2] = 1500;
    TIERS[1][3] = 750;
    TIERS[1][4] = 750;
    TIERS[1][5] = 200;
    TIERS[1][6] = 200;
    TIERS[1][7] = 90;
    TIERS[1][8] = 10;
    
    //HasEyes
    TIERS[2][0] = 8000; 
    TIERS[2][1] = 2000;

    //HasMouth
    TIERS[3][0] = 9000;
    TIERS[3][1] = 1000;

    //BgColor
    TIERS[4][0] = 2000;
    TIERS[4][1] = 2000;
    TIERS[4][2] = 1500;
    TIERS[4][3] = 1500;
    TIERS[4][4] = 1500;
    TIERS[4][5] = 1500;

    //LargeOre
    TIERS[5][0] = 7500;
    TIERS[5][1] = 2500;

    return TIERS;
  }

  function getTraitTypes() internal pure returns (Trait[][6] memory) {
    Trait[][6] memory TIERS = [
      new Trait[](4),
      new Trait[](9),
      new Trait[](2),
      new Trait[](2),
      new Trait[](6),
      new Trait[](2)      
    ];

    //Base
    TIERS[0][0] = Trait('Base', 'Clay');
    TIERS[0][1] = Trait('Base', 'Stone');
    TIERS[0][2] = Trait('Base', 'Metal');
    TIERS[0][3] = Trait('Base', 'Obsidian');

    //Ore
    TIERS[1][0] = Trait('Ore', 'None');
    TIERS[1][1] = Trait('Ore', 'Grass');
    TIERS[1][2] = Trait('Ore', 'Bronze');
    TIERS[1][3] = Trait('Ore', 'Jade');
    TIERS[1][4] = Trait('Ore', 'Gold');
    TIERS[1][5] = Trait('Ore', 'Ruby');
    TIERS[1][6] = Trait('Ore', 'Sapphire');
    TIERS[1][7] = Trait('Ore', 'Amethyst');
    TIERS[1][8] = Trait('Ore', 'Diamond');
    
    //HasEyes
    TIERS[2][0] = Trait('HasEyes', 'No'); 
    TIERS[2][1] = Trait('HasEyes', 'Yes');

    //HasMouth
    TIERS[3][0] = Trait('HasMouth', 'No');
    TIERS[3][1] = Trait('HasMouth', 'Yes');

    //BgColor
    TIERS[4][0] = Trait('BgColor', 'Forest');
    TIERS[4][1] = Trait('BgColor', 'Mountain');
    TIERS[4][2] = Trait('BgColor', 'River');
    TIERS[4][3] = Trait('BgColor', 'Field');
    TIERS[4][4] = Trait('BgColor', 'Cave');
    TIERS[4][5] = Trait('BgColor', 'Clouds');

    //LargeOre
    TIERS[5][0] = Trait('LargeOre', 'No');
    TIERS[5][1] = Trait('LargeOre', 'Yes');

    return TIERS;
  }

    function generateMetadataHash(uint256 _t, uint256 _c)
        internal
        pure
        returns (string memory)
    {
        string memory currentHash = "";
        for (uint8 i = 0; i < 6; i++) {
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(_t, _c))) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        return currentHash;
    }

    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        pure
        returns (string memory)
    {
      uint16[][6] memory TIERS = getTiers();
      uint16 currentLowerBound = 0;
      for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
          uint16 thisPercentage = TIERS[_rarityTier][i];
          if (
              _randinput >= currentLowerBound &&
              _randinput < currentLowerBound + thisPercentage
          ) return ClayLibrary.toString(i);
          currentLowerBound = currentLowerBound + thisPercentage;
      }

      revert();
    }

    function renderAttributesFromHash(string memory _hash, uint256 _t) internal pure returns (string memory) {
      uint256 seed = uint256(keccak256(abi.encodePacked(_t, ClayLibrary.SEED))) % 100000;
      Trait[][6] memory traitTypes = getTraitTypes();
      string memory metadataString;
      for (uint8 i = 0; i < 6; i++) {
          uint8 thisTraitIndex = ClayLibrary.parseInt(ClayLibrary.substring(_hash, i, i + 1));
          Trait memory trait = traitTypes[i][thisTraitIndex];
          metadataString = string(
              abi.encodePacked(
                  metadataString,
                  '{"trait_type":"',
                  trait.traitType,
                  '","value":"',
                  trait.traitName,
                  '"}'
              )
          );

          metadataString = string(abi.encodePacked(metadataString, ","));
      }

      metadataString = string(
          abi.encodePacked(
              metadataString,
              '{"trait_type":"Seed","value":"',
              ClayLibrary.toString(seed),
              '"}'
          )
      );

      return metadataString;
    }

    function renderAttributes(uint256 _t) internal pure returns (string memory) {
      string memory _hash = generateMetadataHash(_t, ClayLibrary.SEED);
      return renderAttributesFromHash(_hash, _t);
    }
}
