// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IOwnable{
    function owner() external view returns(address);
    function transferOwnership(address _newOwner) external;
    function setDBControlWhitelist(address[] memory _modules,bool[] memory _status)  external;
    function getDBControlWhitelist(address _module) external view returns(bool);
}