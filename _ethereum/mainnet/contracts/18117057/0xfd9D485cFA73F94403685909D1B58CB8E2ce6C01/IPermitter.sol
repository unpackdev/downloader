// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title IPermitter
 * @notice Interface for the Permitter contracts. They are used to check whether a set of tokenIds
 *   are are allowed in a pool.
 */
interface IPermitter {
    /**
     * @notice Initializes the permitter contract with initial state.
     * @param data_ Any data necessary for initializing the permitter implementation.
     */
    function initialize(bytes memory data_) external returns (bytes memory);

    /**
     * @notice Returns whether or not the contract has been initialized.
     * @return initialized Whether or not the contract has been initialized.
     */
    function initialized() external view returns (bool);

    /**
     * @notice Checks that the provided permission data are valid for the provided tokenIds.
     * @param tokenIds_ The token ids to check.
     * @param permitterData_ data used by the permitter to perform checking.
     * @return permitted Whether or not the tokenIds are permitted to be added to the pool.
     */
    function checkPermitterData(uint256[] calldata tokenIds_, bytes memory permitterData_)
        external
        view
        returns (bool permitted);
}
