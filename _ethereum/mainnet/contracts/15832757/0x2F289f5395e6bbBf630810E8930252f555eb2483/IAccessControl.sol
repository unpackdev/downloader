// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccessControl {
    function MANAGER_ROLE() external view returns (bytes32);

    function hasRole(bytes32 _role, address _account) external view returns (bool);
}
