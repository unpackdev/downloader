// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICode {
    function getCode(string calldata params) external view returns (string memory);
}
