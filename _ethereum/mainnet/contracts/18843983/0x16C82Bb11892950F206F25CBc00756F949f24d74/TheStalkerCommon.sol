// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// the stalker by int.art
// a permissionless collaboration program running on EVM.

interface ITheStalkerRenderer {
    function canUpdateToken(
        address sender,
        uint256 tokenId,
        uint256 targetTokenId
    ) external view returns (bool);

    function isTokenRenderable(
        uint256 tokenId,
        uint256 targetTokenId
    ) external view returns (bool);

    function tokenHTML(
        uint256 tokenId,
        uint256 targetTokenid
    ) external view returns (string memory);

    function tokenImage(
        uint256 tokenId,
        uint256 targetTokenid
    ) external view returns (string memory);

    function tokenURI(
        uint256 tokenId,
        uint256 targetTokenid
    ) external view returns (string memory);
}
