// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12; 

interface IOptionsManager {
    function depositOption(address from, uint tokenId, uint premium) external;
    function withdrawOption(address to, uint tokenId) external;
    function exerciseOption(uint tokenId) external;
    function unlockOption(uint tokenId) external;
}