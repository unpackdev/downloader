// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;


/// @title Crypto Bear Watch Club Pieces Interface
/// @author Kfish n Chips
/// @notice Interface of CBWC Staking contract
/// @custom:security-contact security@kfishnchips.com
interface ICBWCStaking {
    /// @notice Stores token id staker address
    /// @dev mapping(uint256 => address) public tokenOwner
    /// @param tokenId_ the token ID to get the owner
    /// @return the address of the owner
    function tokenOwner(uint256 tokenId_) external view returns (address);
}
