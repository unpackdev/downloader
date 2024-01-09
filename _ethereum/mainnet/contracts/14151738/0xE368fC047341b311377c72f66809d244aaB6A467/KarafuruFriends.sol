// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721Opensea.sol";

/// @title Karafuru Friends
/// @author 69hunter
contract KarafuruFriends is ERC721Opensea {
    constructor() ERC721("Karafuru Friends", "KARAFURU-FRIENDS") {}

    /// @notice Gift new tokens for `receivers`.
    /// @param receivers addresses to receive newly created tokens
    function gift(address[] calldata receivers) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
}
