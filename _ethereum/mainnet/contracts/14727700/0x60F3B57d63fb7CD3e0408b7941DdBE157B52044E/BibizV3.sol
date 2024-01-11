// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./BibizV2.sol";

contract BibizV3 is BibizV2 {

    event AdminTransfer(address indexed sender, address from, address to, uint256 tokenId);

    /// @notice admin transfer of token from one address to another and meant to be used with extreme care
    /// @dev only callable from the owner
    /// @param from_ the address that holds the tokenId
    /// @param to_ the address which will receive the tokenId
    /// @param tokenId_ the key's tokenId
    function adminTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) external onlyAdminOrOwner {
        _adminTransferFrom(from_, to_, tokenId_);
        emit AdminTransfer(msg.sender, from_, to_, tokenId_);
    }
}
