// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721Opensea.sol";

/// @title Monaverse Honorary
/// @author 69hunter
contract Karafuru3DHonoraries is ERC721Opensea {
    constructor() ERC721("Karafuru x HYPEBEAST x atmos Honoraries", "3D-KARA-HON") {}

    /// @notice Gift new tokens for `receivers`.
    /// @param receivers addresses to receive newly created tokens
    function gift(address[] calldata receivers) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
}
