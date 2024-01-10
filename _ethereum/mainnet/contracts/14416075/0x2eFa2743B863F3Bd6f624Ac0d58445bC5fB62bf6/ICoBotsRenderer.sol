// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ICoBotsRenderer {
    function tokenURI(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) external view returns (string memory);
}
