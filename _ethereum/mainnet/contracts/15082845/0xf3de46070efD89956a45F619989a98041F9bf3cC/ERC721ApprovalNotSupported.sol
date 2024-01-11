// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";

error NotSupported();

/// @title Override the standard ERC721 approval functions so that they are not supported.
/// @dev Throws the NotSupported error and reverts when any of these functions are called.
/// @custom:documentation https://roofstock-onchain.gitbook.io/roofstock-ideas/v1/home-ownership-token-genesis#approval-not-supported
abstract contract ERC271ApprovalNotSupported is ERC721Upgradeable {
    function approve(address to, uint256 tokenId)
        public
        virtual
        override
    {
        to;
        tokenId;
        revert NotSupported();
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        tokenId;
        revert NotSupported();
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        owner;
        operator;
        revert NotSupported();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        operator;
        approved;
        revert NotSupported();
    }
}
