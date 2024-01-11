/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface IBooster {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}
