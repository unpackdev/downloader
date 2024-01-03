// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./ISplitAtomicV0.sol";

interface ISplitAtomicFactoryV0 {
    /**
     * @notice This contract was deployed.
     * @param implementation address with the implementation of the contract
     * @param type_ type of this contract
     * @param requiredSplitAddress address that must be included in all splits
     * @param requiredSplitBasisPoints basis points that must be included in
     * all splits
     */
    event Deployed(
        address indexed implementation,
        bytes32 indexed type_,
        address requiredSplitAddress,
        uint16 requiredSplitBasisPoints
    );
    /**
     * @notice New split atomic contract was created.
     * @param splitAtomic address of the newly created split atomic contract
     */
    event SplitAtomicCreated(address indexed splitAtomic);
    /**
     * @notice This contract was abandoned and no longer can be used to create
     * new split atomic contracts.
     */
    event Abandoned();

    /**
     * @notice Initializes the contract with the provided `splits`.
     * Only callable once.
     * @param splits Splits to configure the contract with. Must add up to
     * 10_000 BPS.
     * @return splitAtomic The address of the newly created split atomic
     * contract
     */
    function createSplit(
        Split[] calldata splits
    ) external returns (address splitAtomic);

    /**
     * @notice The implementation contract that is cloned when creating new
     * split atomic contracts.
     */
    function splitAtomicImplementation() external view returns (address);

    /**
     * @notice The address that must be included in all splits.
     */
    function requiredSplitAddress() external view returns (address);

    /**
     * @notice The basis points that must be included in all splits, for the
     * required split address.
     */
    function requiredSplitBasisPoints() external view returns (uint16);

    /**
     * @notice The deployer of the contract.
     */
    function deployer() external view returns (address);

    /**
     * @notice Indicates whether the contract is abandoned.
     * Once abandoned, the contract can no longer be used to create new split
     * atomic contracts.
     * @return bool True if the contract is abandoned, false otherwise.
     */
    function isAbandoned() external view returns (bool);

    /**
     * @notice Indicates the type of the contract, e.g. `SplitAtomicFactoryV0`.
     * @return type_ The type of the contract.
     */
    function type_() external pure returns (bytes32);
}
