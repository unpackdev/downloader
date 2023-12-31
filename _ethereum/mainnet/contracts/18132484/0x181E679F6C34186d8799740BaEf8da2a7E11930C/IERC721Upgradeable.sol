// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC721Upgradeable {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function burn(uint256 tokenId) external;
}
