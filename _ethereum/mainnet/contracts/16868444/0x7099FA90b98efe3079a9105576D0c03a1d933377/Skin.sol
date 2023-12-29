// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./DefaultOperatorFilterer.sol";

/// @title Skin contract
/// @custom:juice 100%
/// @custom:security-contact charles@branch.gg
contract Skin is ERC721, ERC721Burnable, Pausable, Ownable, AccessControl, DefaultOperatorFilterer {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    using Counters for Counters.Counter;

    string public baseURI;
    uint256 public maxSupply;

    Counters.Counter private tokenIdCounter;

    constructor(string memory baseURI_, uint256 maxSupply_)
        ERC721("Skin", "SKIN")
    {
        baseURI = baseURI_;
        maxSupply = maxSupply_;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(AIRDROP_ROLE, _msgSender());
    }

    function airdrop(address[] calldata recipients)
        public
        whenNotPaused
        onlyRole (AIRDROP_ROLE)
    {
        require(tokenIdCounter.current() + recipients.length <= maxSupply, "Skin: exceeds max supply");
    
        for (uint256 i = 0; i < recipients.length; i++)
        {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _mint(recipients[i], tokenId);
        }
    }

    function pause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _unpause();
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return tokenIdCounter.current();
    }

    function setBaseURI(string calldata baseURI_)
        external
        onlyRole (MANAGER_ROLE)
    {
        baseURI = baseURI_;
    }

     function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval (operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval (operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval (from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval (from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator (from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
