// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IProxy {
    function upgradeTo(address impl) external;
}
