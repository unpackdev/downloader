// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IStorageV1 {
    function governance() external view returns(address);
    function treasury() external view returns(address);
    function isAdmin(address _target) external view returns(bool);
    function isOperator(address _target) external view returns(bool);
}