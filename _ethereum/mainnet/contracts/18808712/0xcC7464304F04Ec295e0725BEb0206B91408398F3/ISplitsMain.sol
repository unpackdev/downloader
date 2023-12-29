// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title ISplitsMain
 * @author 0xSplits
 * @notice Interface for SplitsFactory to interact with SplitsMain
 */
interface ISplitsMain {
    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address controller
    ) external returns (address);

    function distributeETH(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function getHash(address split) external view returns (bytes32);

    function predictImmutableSplitAddress(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee
    ) external view returns (address);

    function updateSplit(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee
    ) external;

    function withdraw(address account, uint256 withdrawETH, address[] calldata tokens) external;
}
