//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaider {
    struct Raider {
        uint256 dna;
        uint256 active_weapon;
    }

    struct RaiderTraits {
        bool isFemale;
        uint256 skin;
        uint256 hair;
        uint256 boots;
        uint256 pants;
        uint256 outfit;
        uint256 headwear;
        uint256 accessory;
        uint256 active_weapon;
    }

    function getTokenRaider(uint256 _tokenId) external view returns (Raider memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
