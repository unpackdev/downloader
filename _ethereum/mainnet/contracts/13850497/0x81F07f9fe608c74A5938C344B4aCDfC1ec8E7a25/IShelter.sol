// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.10;

interface IShelter {
    function addManyToShelterAndPack(
        address account,
        uint16[] calldata tokenIds
    ) external;

    // struct to store each token's traits
    struct PupCat {
        bool isPup;
        uint8 alphaIndex;
        bool isDogCatcher;
    }
}
