// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface WhIn {
    function checkWhitelist(address account) external view returns (bool);
    event WhitelistChange(address indexed account, bool indexed status);
}