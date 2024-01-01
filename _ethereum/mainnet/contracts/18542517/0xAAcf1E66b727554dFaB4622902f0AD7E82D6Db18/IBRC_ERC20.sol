
//SPDX-License-Identifier: MIT
//@author Matheus Rosendo
pragma solidity ^0.8.10;

interface IBRC_ERC20 {

    function addMinter(address _newMinter) external;
    function addAdmin(address _newMinter) external;
    function isMinter(address _verifyAddr) external view returns (bool);
    function isAdmin(address _verifyAddr) external view returns (bool);
}