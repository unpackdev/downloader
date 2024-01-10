// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IHardBlocksStudent {
    function tokenURI(
        uint256 tokenId,
        string memory studentName,
        uint256 score
    ) external view returns (string memory);
}
