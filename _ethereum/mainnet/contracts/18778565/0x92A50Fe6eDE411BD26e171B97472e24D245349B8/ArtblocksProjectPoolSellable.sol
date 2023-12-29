// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import "./ERC721ACommon.sol";
import {GenArt721CoreV3_Engine_Flex_PROOF} from
    "artblocks-contracts/engine/V3/forks/GenArt721CoreV3_Engine_Flex_PROOF.sol";
import "./MinterFilterV2.sol";
import "./ISharedMinterRequired.sol";

import "./TokenIDMapping.sol";
import "./IGenArt721CoreContractV3_Mintable.sol";

import "./ProjectPoolSellable.sol";

/**
 * @title ArtBlocks enabled Project Pool Sellable
 * @notice A pool of sequentially indexed, sellable projects with ArtBlocks support and max supply
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 * @custom:reviewer Josh Laird (@jbmlaird)
 */
abstract contract ArtblocksProjectPoolSellable is ProjectPoolSellable {
    // =================================================================================================================
    //                          Constants
    // =================================================================================================================

    /**
     * @notice The ArtBlocks engine flex contract.
     */
    GenArt721CoreV3_Engine_Flex_PROOF public immutable flex;

    // =================================================================================================================
    //                          Construction
    // =================================================================================================================

    constructor(Init memory init, GenArt721CoreV3_Engine_Flex_PROOF flex_) ProjectPoolSellable(init) {
        flex = flex_;
    }

    // =================================================================================================================
    //                          Configuration
    // =================================================================================================================

    /**
     * @notice Returns true iff the project is a longform project.
     */
    function _isLongformProject(uint128 projectId) internal view virtual returns (bool);

    /**
     * @notice Returns the ArtBlocks engine project IDs for the longform projects.
     */
    function _artblocksProjectId(uint128 projectId) internal view virtual returns (uint256);

    // =================================================================================================================
    //                          Selling
    // =================================================================================================================

    /**
     * @notice Handles the minting of a token from a given project.
     * @dev Mints from the associated ArtBlocks project if the project is a longform project and locks the token in the
     * contract.
     */
    function _handleProjectMinted(uint256 tokenId, uint128 projectId, uint64 edition) internal virtual override {
        super._handleProjectMinted(tokenId, projectId, edition);

        if (_isLongformProject(projectId)) {
            _mintArtblocksToken(_artblocksProjectId(projectId));
        }
    }

    function _mintArtblocksToken(uint256 artblocksProjectId) internal virtual;

    // =================================================================================================================
    //                          Metadata
    // =================================================================================================================

    /**
     * @inheritdoc ERC721A
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        TokenInfo memory info = tokenInfo(tokenId);

        if (_isLongformProject(info.projectId)) {
            return flex.tokenURI(artblocksTokenID(_artblocksProjectId(info.projectId), info.edition));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @notice Helper function that returns true if the token belongs to a longform project.
     */
    function _isLongformToken(uint256 tokenId) internal view virtual returns (bool) {
        return _isLongformProject(tokenInfo(tokenId).projectId);
    }

    // =================================================================================================================
    //                          Inheritance resolution
    // =================================================================================================================

    // Artblocks does not permit partners to have operator filtering on any of their tokens (even if they are wrapped
    // like in this contract). We therefore selectively enable/disable the filtering based on the project type.

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override {
        if (_isLongformToken(tokenId)) {
            ERC721A.transferFrom(from, to, tokenId);
        } else {
            ProjectPoolSellable.transferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override {
        if (_isLongformToken(tokenId)) {
            ERC721A.safeTransferFrom(from, to, tokenId);
        } else {
            ProjectPoolSellable.safeTransferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override
    {
        if (_isLongformToken(tokenId)) {
            ERC721A.safeTransferFrom(from, to, tokenId, data);
        } else {
            ProjectPoolSellable.safeTransferFrom(from, to, tokenId, data);
        }
    }

    function approve(address operator, uint256 tokenId) public payable virtual override {
        if (_isLongformToken(tokenId)) {
            ERC721A.approve(operator, tokenId);
        } else {
            ProjectPoolSellable.approve(operator, tokenId);
        }
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        // Excluding any filtering here since `approvalForAll` will also affect Artblocks tokens.
        ERC721A.setApprovalForAll(operator, approved);
    }
}

abstract contract ArtblocksCoreV3MintableProjectPoolSellable is ArtblocksProjectPoolSellable {
    /**
     * @notice The ArtBlocks engine flex contract or a minter multiplexer.
     */
    IGenArt721CoreContractV3_Mintable public immutable flexMintGateway;

    constructor(
        Init memory init,
        GenArt721CoreV3_Engine_Flex_PROOF flex_,
        IGenArt721CoreContractV3_Mintable flexMintGateway_
    ) ArtblocksProjectPoolSellable(init, flex_) {
        flexMintGateway = flexMintGateway_;
    }

    function _mintArtblocksToken(uint256 artblocksProjectId) internal virtual override {
        flexMintGateway.mint_Ecf({to: address(this), projectId: artblocksProjectId, sender: address(this)});
    }
}

abstract contract ArtblocksWithMinterFilterV2ProjectPoolSellable is
    ArtblocksProjectPoolSellable,
    ISharedMinterRequired
{
    /**
     */
    MinterFilterV2 public immutable minterFilter;

    constructor(Init memory init, GenArt721CoreV3_Engine_Flex_PROOF flex_, MinterFilterV2 minterFilter_)
        ArtblocksProjectPoolSellable(init, flex_)
    {
        minterFilter = minterFilter_;
    }

    function _mintArtblocksToken(uint256 artblocksProjectId) internal virtual override {
        minterFilter.mint_joo({
            to: address(this),
            projectId: artblocksProjectId,
            coreContract: address(flex),
            sender: address(this)
        });
    }

    function minterType() external pure returns (string memory) {
        return "ArtblocksWithMinterFilterV2ProjectPoolSellable";
    }

    function minterFilterAddress() external view returns (address) {
        return address(minterFilter);
    }
}
