// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IInstaMemory {
    function getUint(uint256 _id) external returns (uint256 _num);

    function setUint(uint256 _id, uint256 _val) external;
}
