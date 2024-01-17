// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: ERC721DelegateALockable
/// @author: Pacy

import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721MintableUpgradeableA.sol";
import "./IERC721Delegate.sol";
import "./ERC5192.sol";

contract ERC721DelegateALockable is
    ERC721MintableUpgradeableA,
    ReentrancyGuardUpgradeable,
    ERC5192,
    IERC721Delegate
{
    string public baseURI;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) public initializer {
        ERC721Upgradeable.__ERC721_init(name_, symbol_);
        AccessControlUpgradeable.__AccessControl_init();
        AccessControlUpgradeable._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._setupRole(OPERATOR, msg.sender);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        setBaseURI(baseURI_);
        setLockPeriodInEffect(true);
    }

    function setBaseURI(string memory baseURI_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setLockPeriodInEffect(bool state_)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super.setLockPeriodInEffect(state_);
    }

    function lock(uint256 tokenId_) public override onlyOperator {
        super.lock(tokenId_);
    }

    function unlock(uint256 tokenId_) public override onlyOperator {
        super.unlock(tokenId_);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override
        whenNotLocked(tokenId)
    {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool _approved)
        public
        virtual
        override
        whenNotLockPeriodInEffect
    {
        super.setApprovalForAll(operator, _approved);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotLocked(tokenId) {
        super._transfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721MintableUpgradeableA, ERC5192)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
