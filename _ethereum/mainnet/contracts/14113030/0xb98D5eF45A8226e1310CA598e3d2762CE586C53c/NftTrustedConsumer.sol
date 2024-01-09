// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";

abstract contract NftTrustedConsumer is ERC721 {
    // Enable future consumption of the contract (without approvals)
    address public _trustedConsumer = address(0x0);

    function _setTrustedConsumer(address trustedConsumer) internal virtual {
        require(trustedConsumer != address(0x0), "trustedConsumer Need a valid address");
        _trustedConsumer = trustedConsumer;
    }

    // auto approve the trusted contract interactions otherwise standard approvals.
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return ((_trustedConsumer != address(0x0) && _msgSender() == _trustedConsumer) ||
            super._isApprovedOrOwner(spender, tokenId));
    }
}
