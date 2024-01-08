// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IMemberController {
    function getMember(string memory name) external view returns(address addr);
    function setMember(string memory name, address member) external;
}