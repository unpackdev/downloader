// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
pragma abicoder v2;

interface IMintywayRoyalty {
    function royaltyOf(uint256 _id) external view returns(uint256);
    function creatorOf(uint256 _id) external view returns(address);
}