// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenStakingPoolExtension {
    function setShare(
        address wallet,
        uint256 balanceChange,
        bool isRemoving
    ) external;
}