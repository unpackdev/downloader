// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IBlitoadzRenderer {
    function tokenURI(
        uint256 toadzId,
        uint256 blitmapId,
        uint8 paletteOrder
    ) external view returns (string memory);
}
