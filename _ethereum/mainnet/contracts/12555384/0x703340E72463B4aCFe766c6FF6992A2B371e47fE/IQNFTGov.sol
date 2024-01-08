// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQNFTGov {
    function updateVote(
        address user,
        uint256 originAmount,
        uint256 currentAmount
    ) external;
}
