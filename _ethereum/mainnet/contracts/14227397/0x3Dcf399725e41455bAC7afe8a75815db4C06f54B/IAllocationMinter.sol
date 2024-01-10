// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IAllocationMinter {
    function allocationSupplyAt(bytes32 role, uint256 timestamp) external view returns (uint256);
    function allocationAvailable(bytes32 role) external view returns (uint256);
    function allocationMint(address to, bytes32 role, uint256 amount) external;
    function allocationMinted(bytes32 role) external view returns (uint256);
}
