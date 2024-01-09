// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IPnG is IERC721 {

    struct GalleonPirate {
        bool isGalleon;

        // Galleon traits
        uint8 base;
        uint8 deck;
        uint8 sails;
        uint8 crowsNest;
        uint8 decor;
        uint8 flags;
        uint8 bowsprit;

        // Pirate traits
        uint8 skin;
        uint8 clothes;
        uint8 hair;
        uint8 earrings;
        uint8 mouth;
        uint8 eyes;
        uint8 weapon;
        uint8 hat;
        uint8 alphaIndex;
    }


    function updateOriginAccess(uint16[] memory tokenIds) external;

    function totalSupply() external view returns(uint256);

    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function minted() external view returns (uint16);

    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (GalleonPirate memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isGalleon(uint256 tokenId) external view returns(bool);
}