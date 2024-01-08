// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAuqaPrimary {
    function stake(
        uint256 tokenIdOrAmount,
        address handler,
        address contractAddress,
        bytes calldata data
    ) external;

    function unstake(bytes32[] calldata id, uint256[] calldata tokenValue) external;

    function unstakeSingle(bytes32 id, uint256 tokenValue) external;
}
