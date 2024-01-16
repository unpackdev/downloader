// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IBettingPool{
    function checkBettingContractExist(address _pool) external  returns (bool);
}