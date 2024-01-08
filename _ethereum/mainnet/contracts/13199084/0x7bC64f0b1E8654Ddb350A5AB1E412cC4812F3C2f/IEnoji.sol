//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IEnoji {
    function getEmojis(uint256 tokenId)
        external
        view
        returns (string memory, string memory);

    function getColors(uint256 tokenId)
        external
        view
        returns (string memory, string memory);
}
