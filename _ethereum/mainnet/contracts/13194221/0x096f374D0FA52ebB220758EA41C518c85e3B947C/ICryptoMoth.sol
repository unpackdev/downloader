//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "./IERC721EnumerableUpgradeable.sol";

interface ICryptoMoth is IERC721EnumerableUpgradeable {
    function mint(uint blockId, address to) external;
    function isMinted(uint blockId) external view returns (bool);
    function dnaForBlockNumber(uint _blockNumber) external pure returns (uint);
    function blockOfToken(uint tokenId) external view returns (uint);
}