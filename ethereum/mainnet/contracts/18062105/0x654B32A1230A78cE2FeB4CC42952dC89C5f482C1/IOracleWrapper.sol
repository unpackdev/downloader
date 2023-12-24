// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IOracleWrapper {
    function getPrice0() external view returns (uint256 price0);

    function getPrice1() external view returns (uint256 price1);
}
