// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Renderable {
    struct Mutyte {
        uint256 dna;
        uint256 colorId;
        uint256 bodyId;
        uint256 cheeksId;
        uint256 legsId;
        bool[2] legs;
        uint256 armsId;
        bool[2] arms;
        uint256 earsId;
        bool[5] ears;
        uint256 eyesId;
        bool[8] eyes;
        uint256 noseId;
        uint256 mouthId;
        uint256 teethId;
        uint256 bgShapes;
        uint256 mutationLevel;
    }

    function fromDNA(uint256 dna) internal pure returns (Mutyte memory) {
        Mutyte memory mutyte;
        dna >>= 202;
        mutyte.dna = dna;
        mutyte.colorId = (dna >> 51) & 7;
        mutyte.bodyId = (dna >> 48) & 7;
        mutyte.cheeksId = (dna >> 46) & 3;
        mutyte.legsId = (dna >> 43) & 7;
        mutyte.legs = [(dna >> 42) & 1 == 1, (dna >> 41) & 1 == 1];
        mutyte.armsId = (dna >> 38) & 7;
        mutyte.arms = [(dna >> 37) & 1 == 1, (dna >> 36) & 1 == 1];
        mutyte.earsId = (dna >> 33) & 7;
        mutyte.ears = [
            (dna >> 32) & 1 == 1,
            (dna >> 31) & 1 == 1,
            (dna >> 30) & 1 == 1,
            (dna >> 29) & 1 == 1,
            (dna >> 28) & 1 == 1
        ];
        mutyte.eyesId = (dna >> 25) & 7;
        mutyte.eyes = [
            (dna >> 24) & 1 == 1,
            (dna >> 23) & 1 == 1,
            (dna >> 22) & 1 == 1,
            (dna >> 21) & 1 == 1,
            (dna >> 20) & 1 == 1,
            (dna >> 19) & 1 == 1,
            (dna >> 18) & 1 == 1,
            (dna >> 17) & 1 == 1
        ];
        mutyte.noseId = (dna >> 14) & 7;
        mutyte.mouthId = (dna >> 11) & 7;
        mutyte.teethId = (dna >> 8) & 7;
        mutyte.bgShapes = (dna) & 0xFF;

        uint256 variation = (((dna >> 41) & 1) +
            ((dna >> 37) & 1) +
            ((dna >> 36) & 1)) +
            (((dna >> 32) & 1) +
                ((dna >> 31) & 1) +
                ((dna >> 30) & 1) +
                ((dna >> 29) & 1) +
                ((dna >> 28) & 1)) +
            (((dna >> 24) & 1) +
                ((dna >> 23) & 1) +
                ((dna >> 22) & 1) +
                ((dna >> 21) & 1) +
                ((dna >> 20) & 1) +
                ((dna >> 19) & 1) +
                ((dna >> 18) & 1) +
                ((dna >> 17) & 1));

        if (variation > 7) {
            mutyte.mutationLevel = variation - 7;
            if (mutyte.mutationLevel > 7) {
                mutyte.mutationLevel = 7;
            }
        }

        return mutyte;
    }
}
