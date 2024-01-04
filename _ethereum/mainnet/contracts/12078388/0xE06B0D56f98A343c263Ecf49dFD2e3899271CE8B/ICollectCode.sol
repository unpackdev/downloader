// SPDX-License-Identifier: MIT
// Same version as openzeppelin 3.4
pragma solidity >=0.6.0 <0.8.0;

interface ICollectCode
{
    function makePixels(bytes20 s0, bytes20 s1, bytes20 s2, uint256 tokenId) external pure returns (bytes memory);
}
