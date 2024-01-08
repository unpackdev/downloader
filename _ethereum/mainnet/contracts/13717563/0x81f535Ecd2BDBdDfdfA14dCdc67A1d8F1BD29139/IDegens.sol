// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IDegens is IERC721 {

    // struct to store each token's traits
    struct Degen {
        uint8 degenType;
        uint8 accessories;
        uint8 clothes;
        uint8 eyes;
        uint8 background;
        uint8 mouth;
        uint8 body;
        uint8 hairdo;
        uint8 alphaIndex;
    }

    function getDegenTypeName(Degen memory _degen) external view returns (string memory);

    function getNFTName(Degen memory _degen) external view returns (string memory);

    function getNFTGeneration(uint256 tokenId) external pure returns (string memory);

    function getPaidTokens() external view returns (uint256);

    function getTokenTraits(uint256 tokenId) external view returns (Degen memory);

    function isBull(Degen memory _character) external pure returns (bool);

    function isBears(Degen memory _character) external pure returns (bool);

    function isZombies(Degen memory _character) external pure returns (bool);

    function isApes(Degen memory _character) external pure returns (bool);
}
