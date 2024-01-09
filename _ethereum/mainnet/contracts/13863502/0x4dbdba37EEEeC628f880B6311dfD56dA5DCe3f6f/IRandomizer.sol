// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function random(uint256) external returns (uint256);

    function canOperate(address addr, uint256 tokenId) external returns (bool);
}