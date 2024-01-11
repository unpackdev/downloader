// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.1;

interface IWildAbduction {

    // struct to store each token's traits
    struct CowboyAlien {
        bool isCowboy;
        bool isMutant;
        uint8 pants;
        uint8 top;
        uint8 hat;
        uint8 weapon;
        uint8 accessory;
        uint8 alphaIndex;
    }

    function minted() external returns (uint16);
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (CowboyAlien memory);
}