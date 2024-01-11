// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721ApprovalNotSupported.sol";
import "./ERC721BaseURI.sol";
import "./ERC721Burnable.sol";
import "./ERC721Mintable.sol";
import "./ERC721TransferrerOnly.sol";

/// @title A non-fungible token that represents ownership of a home.
/// @dev This contract only overrides required functions from inherited extensions.
/// @custom:documentation https://roofstock-onchain.gitbook.io/roofstock-ideas/v1/home-ownership-token-genesis
contract HomeOwnershipToken is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, ERC271ApprovalNotSupported, ERC721TransferrerOnly, ERC721BaseURI, ERC721Mintable, ERC721Burnable {
    function initialize()
        initializer
        public
    {
        __ERC721_init("Home Ownership Token", "HOT");
        __ERC721BaseURI_init("https://onchain.roofstock.com/metadata/");
        __ERC721Enumerable_init();
        __AccessControl_init();
        __ERC721TransferrerOnly_init();
        __ERC721Mintable_init();
        __ERC721Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, ERC721TransferrerOnly, ERC721BaseURI, ERC721Mintable, ERC721Burnable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721TransferrerOnly, ERC721Upgradeable, IERC721Upgradeable)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
        public
        override(ERC721TransferrerOnly, ERC721Upgradeable, IERC721Upgradeable)
    {
        return super.safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId)
        public
        override(ERC271ApprovalNotSupported, ERC721Upgradeable, IERC721Upgradeable)
    {
        return super.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        override(ERC271ApprovalNotSupported, ERC721Upgradeable, IERC721Upgradeable)
        returns (address)
    {
        return super.getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC271ApprovalNotSupported, ERC721Upgradeable, IERC721Upgradeable)
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC271ApprovalNotSupported, ERC721Upgradeable, IERC721Upgradeable)
    {
        return super.setApprovalForAll(operator, approved);
    }

    function _baseURI()
        internal
        view
        override(ERC721BaseURI, ERC721Upgradeable)
        returns (string memory)
    {
        return super._baseURI();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
