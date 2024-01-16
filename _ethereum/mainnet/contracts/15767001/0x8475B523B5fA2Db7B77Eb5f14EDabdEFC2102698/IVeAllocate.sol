// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVeAllocate {
    function getveAllocation(
        address user,
        address nft,
        uint256 chainid
    ) external view returns (uint256);

    function getTotalAllocation(address user) external view returns (uint256);

    function setAllocation(
        uint256 amount,
        address nft,
        uint256 chainId
    ) external;

    function setBatchAllocation(
        uint256[] calldata amount,
        address[] calldata nft,
        uint256[] calldata chainId
    ) external;
}
