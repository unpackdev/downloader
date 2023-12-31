// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVoter {
    function isOperator(address addr) external view returns (bool);
    function isWhitelisted(address addr) external view returns (bool);
}
