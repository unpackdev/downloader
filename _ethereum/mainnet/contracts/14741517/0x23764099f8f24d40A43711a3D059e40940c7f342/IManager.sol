// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IManager {
    function isAdmin(address _user) external view returns (bool);

    function isGorvernance(address _user) external view returns (bool);
}
