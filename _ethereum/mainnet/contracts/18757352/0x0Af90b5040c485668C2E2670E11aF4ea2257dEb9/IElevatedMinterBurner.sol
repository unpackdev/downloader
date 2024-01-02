// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IElevatedMinterBurner {
    function burn(uint16,address,uint256) external;
    function mint(uint16,address,uint256) external;
}