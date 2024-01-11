// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ICoBotsRenderer {
    function SVG_TAG_START() external view returns (string memory);

    function SVG_TAG_END() external view returns (string memory);

    function tokenURI(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) external view returns (string memory);

    function getRandomItems(uint256 tokenId, uint8 seed)
        external
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        );
}
