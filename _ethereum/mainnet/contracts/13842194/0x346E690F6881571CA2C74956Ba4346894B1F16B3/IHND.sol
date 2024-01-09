// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IHND is IERC721Enumerable {

    // game data storage
    struct HeroDemon {
        bool isHero;
        bool isFemale;
        uint8 body;
        uint8 face;
        uint8 eyes;
        uint8 headpiecehorns;
        uint8 gloves;
        uint8 armor;
        uint8 weapon;
        uint8 shield;
        uint8 shoes;
        uint8 tailflame;
        uint8 rankIndex;
    }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (HeroDemon memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isHero(uint256 tokenId) external view returns(bool);
  
}