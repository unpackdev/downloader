// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IHighriseLand {
    function mint(address user, uint256 tokenId) external;

    function bindToEstate(address owner, uint32[] calldata tokenIds) external;
}
