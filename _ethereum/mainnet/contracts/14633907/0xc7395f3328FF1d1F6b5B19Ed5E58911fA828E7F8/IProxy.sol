// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function proxyOwner() external view returns (address);
}
