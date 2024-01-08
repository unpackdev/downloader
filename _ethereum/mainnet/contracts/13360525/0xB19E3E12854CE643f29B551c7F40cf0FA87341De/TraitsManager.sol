// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Initializable.sol";
import "./Traits.sol";

contract TraitsManager is Traits, Initializable {

    event TraitsSet(Trait[] traits);

    Trait[] traits;

    function __TraitsManager_init_unchained(Trait[] memory _traits) internal initializer {
        for (uint i = 0; i < _traits.length; i++) {
            Trait memory _trait = _traits[i];
            traits.push(_trait);

            uint total = 0;
            for (uint j = 0; j < _trait.rarities.length; j++) {
                total += _trait.rarities[j];
            }
            require(total == 10000, "sum or rarities not equal 10000");
        }
        emit TraitsSet(_traits);
    }

    function getTraitValue(Trait memory trait, uint rnd) internal pure returns (uint) {
        uint total = 0;
        for (uint i = 0; i < trait.rarities.length; i++) {
            total += trait.rarities[i];
            if (rnd < total) {
                return i;
            }
        }
        revert("never");
    }

    function getRandom(uint tokenId, uint i) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(tokenId, i))) % 10000;
    }

    function random(uint seed, uint supply, address to) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(seed, block.timestamp, block.number, block.difficulty, supply, to)));
    }

    function getPossibleTraits() external view returns (Trait[] memory) {
        return traits;
    }

    uint256[50] private __gap;
}
