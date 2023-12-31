// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ICrossmintUpgradeable {
    /// @dev Get the version of the contract.
    /// @return version the version of this contract
    function getVersion() external pure returns (string memory);
}
