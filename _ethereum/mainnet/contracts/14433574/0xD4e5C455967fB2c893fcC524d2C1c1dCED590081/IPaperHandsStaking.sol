// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPaperHandsStaking {
    function transferRewards(address _from, address _to) external;

    function stakeLock(address owner, uint256[] memory tokenIds) external;
}