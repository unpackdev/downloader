// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

interface IFortune {

    function fortuneOf(uint256 tokenId) external view returns (address, uint256);
}
