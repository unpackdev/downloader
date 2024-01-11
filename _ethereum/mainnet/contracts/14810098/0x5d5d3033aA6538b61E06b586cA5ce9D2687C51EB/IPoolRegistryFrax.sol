// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IPoolRegistryFrax {
    //clone a new user vault
    function vaultMap(uint256 _pid, address _user) external view returns (address);
}
