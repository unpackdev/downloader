// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMyDanPass {
    function setMinter(address _minter) external;

    function mint(address to) external returns (uint256);

    function ownerOf(uint256 tokenId) external returns (address);

    function minter() external returns (address);

    function owner() external returns (address);
}
