// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TrustedConsumers.sol";
import "./ERC721.sol";

abstract contract NftTrustedConsumers is ERC721, TrustedConsumers {

    // auto approve the trusted contract interactions otherwise standard approvals.
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return ((isTrusted(_msgSender())) ||
            super._isApprovedOrOwner(spender, tokenId));
    }
}
