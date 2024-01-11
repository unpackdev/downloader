// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.11;

interface IDickManiac {
    function mint(address to) external;

    function getCurrentTokenTracker() external view returns (uint256);

    function grow(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function pcEligible(address owner) external view returns (uint256);

    function pcCount() external view returns (uint256);
}
