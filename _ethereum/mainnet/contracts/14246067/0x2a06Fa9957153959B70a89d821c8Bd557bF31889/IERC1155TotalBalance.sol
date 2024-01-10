//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice a contract that can be withdrawn from by some user
interface IERC1155TotalBalance {

    /// @notice get the total balance for the given token id
    /// @param id the token id
    /// @return the total balance for the given token id
    function totalBalanceOf(uint256 id) external view returns (uint256);

}
