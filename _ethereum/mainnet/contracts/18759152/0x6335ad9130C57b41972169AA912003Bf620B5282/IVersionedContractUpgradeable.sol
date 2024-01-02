// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IVersionedContractUpgradeable
 * @dev This interface provides the versioning getters for contracts.
 */
/// @custom:security-contact tech@alexandrialabs.xyz
interface IVersionedContractUpgradeable {
    /**
     * @dev Returns the base contract type of the contract as a bytes32 value.
     */
    function contractType() external pure returns (bytes32);

    /**
     * @dev Returns the version of the contract as a bytes8 value.
     */
    function contractVersion() external pure returns (bytes8);
}
