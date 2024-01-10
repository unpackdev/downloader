//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC1155TotalBalance.sol";

/// @title ERC1155TotalBalance
/// @notice the total balance of a token type
contract ERC1155TotalBalance is IERC1155TotalBalance {

    // total balance per token id
    mapping(uint256 => uint256) internal _totalBalances;

    /// @notice get the total balance for the given token id
    /// @param id the token id
    /// @return the total balance for the given token id
    function totalBalanceOf(uint256 id) external virtual view override returns (uint256) {
        return _totalBalances[id];
    }

}
