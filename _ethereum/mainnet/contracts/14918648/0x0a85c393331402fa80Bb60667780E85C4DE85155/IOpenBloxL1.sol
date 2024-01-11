// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IOpenBloxL1 is IERC721 {
    function mintBlox(
        uint256 tokenId,
        uint256 genes,
        uint16 generation,
        uint256 parent0Id,
        uint256 parent1Id,
        uint256 ancestorCode,
        address receiver
    ) external;
}
