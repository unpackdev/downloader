// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IChangeName {
    function tokenNameByIndex(uint256 index) external view returns (string memory);
}