// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IERC721Mintable is IERC721 {
    /// Mints an ERC721 token to a specific account.
    /// @dev Should be locked behind a permission.
    /// @param account The account that will receive the minted token.
    function mint(address account) external;
}
