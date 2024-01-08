//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICToken {

    function borrowBalanceStored(address account) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function exchangeRateStored() external view returns (uint);
}