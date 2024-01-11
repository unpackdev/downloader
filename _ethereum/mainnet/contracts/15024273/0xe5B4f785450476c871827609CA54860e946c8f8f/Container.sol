// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./ERC721Preset.sol";

error ApprovalOnlyAllowedForApproveRole();

/**
 * @title MRL Container
 * @dev ERC721 for the https://monsterracingleague.com project, this is the container
 * @author Phat Loot DeFi Developers
 * @custom:version v1.0
 * @custom:date 24 June 2022
 */
contract Container is ERC721Preset {
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant APPROVE_ROLE = keccak256("APPROVE_ROLE");

    constructor() ERC721Preset("MRL Container", "CONTAINER") {
        _grantRole(MINT_ROLE, msg.sender);
        _grantRole(APPROVE_ROLE, msg.sender);
    }

    function safeMint(address to) external onlyRole(MINT_ROLE) returns (uint256 tokenId) {
        tokenId = _safeMint(to);
        _flipLock(tokenId);

        return tokenId;
    }

    /**
     * @dev Revert except for APPROVE_ROLE to disallow listing on marketplaces
     */
    function approve(address to, uint256 tokenId) public virtual override {
        if (!hasRole(APPROVE_ROLE, to)) revert ApprovalOnlyAllowedForApproveRole();

        super.approve(to, tokenId);
    }

    /**
     * @dev Revert except for APPROVE_ROLE to disallow listing on marketplaces
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (!hasRole(APPROVE_ROLE, operator)) revert ApprovalOnlyAllowedForApproveRole();

        super.setApprovalForAll(operator, approved);
    }
}
