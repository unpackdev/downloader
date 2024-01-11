//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAdmins {
    function isAdmin(address to) external view returns (bool);
    function setAdmin(address to, bool value) external;
}