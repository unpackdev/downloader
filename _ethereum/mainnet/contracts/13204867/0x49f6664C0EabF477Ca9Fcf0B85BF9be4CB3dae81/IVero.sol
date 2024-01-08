// contracts/Vero.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VeroStatuses.sol";

/// @title Smart contract interface for Virtual Equivalents of Real Objects, or VEROs for short
/// @notice Find additional details in VERO smart contract implementation (Vero.sol)
/// @author Joe Cora
interface IVero {
    function pause() external;
    function unpause() external;
    function getVeroAdmin() external view returns (address);
    function changeVeroAdmin(address newAdmin) external;
    function createAsPending(string memory _tokenURI) external returns (uint256);
    function getVeroStatus(uint256 _tokenId) external view returns (VeroStatuses);
    function approveAsVero(uint256 _tokenId) external;
    function rejectAsVero(uint256 _tokenId) external;
    function revokeAsVero(uint256 _tokenId) external;
}
