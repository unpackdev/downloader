// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

/// @title Override the standard ERC721 transfer functions so that they only work for a transferrer role.
/// @dev Checks that the caller is the transferrer role before transferring.
/// @custom:documentation https://roofstock-onchain.gitbook.io/roofstock-ideas/v1/home-ownership-token-genesis#transferrer-role-only
abstract contract ERC721TransferrerOnly is Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    bytes32 public constant TRANSFERRER_ROLE = keccak256("TRANSFERRER_ROLE");

    function __ERC721TransferrerOnly_init()
        internal
        onlyInitializing
    {
        _grantRole(TRANSFERRER_ROLE, msg.sender);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        virtual
        override
    {
        _checkRole(TRANSFERRER_ROLE);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
        public
        virtual
        override
    {
        _checkRole(TRANSFERRER_ROLE);
        _safeTransfer(from, to, tokenId, _data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
