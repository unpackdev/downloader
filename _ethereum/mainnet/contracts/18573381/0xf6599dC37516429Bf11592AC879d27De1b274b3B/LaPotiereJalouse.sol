// SPDX-License-Identifier: MIT
// Copyright 2023 Divergent Tech Ltd
pragma solidity ^0.8.19;

import "./Address.sol";
import "./SellableERC721ACommon.sol";
import "./BaseTokenURI.sol";
import "./OperatorFilterOS.sol";
import "./ERC721A.sol";

/**
 * @title La Potière Jalouse: Rite of the Handmade
 * @author Arran Schlosberg (@divergencearran)
 * @custom:reviewer David Huber (@cxkoda)
 */
contract LaPotiereJalouse is SellableERC721ACommon, BaseTokenURI, OperatorFilterOS {
    using Address for address payable;

    /**
     * @notice Thrown if an attempt is made to mint tokens beyond MAX_SUPPLY.
     */
    error InsufficientSupply(uint256 requested, uint256 remaining);

    /**
     * @notice Maximum number of tokens mintable.
     */
    uint256 public constant MAX_SUPPLY = 75;

    /**
     * @notice Role allowed to withdraw sales proceeds.
     */
    bytes32 public constant WITHDRAWAL_ROLE = keccak256("WITHDRAWAL_ROLE");

    /**
     * @dev Parameter struct for the constructor.
     */
    struct CtorArgs {
        address admin;
        address steerer;
        string name;
        string symbol;
        address payable royaltyReceiver;
        uint96 royaltyBasisPoints;
        string baseTokenURI;
    }

    constructor(CtorArgs memory args)
        ERC721ACommon(args.admin, args.steerer, args.name, args.symbol, args.royaltyReceiver, args.royaltyBasisPoints)
        BaseTokenURI(args.baseTokenURI)
    {
        _setRoleAdmin(WITHDRAWAL_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @dev Limits total supply to MAX_SUPPLY.
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        if (from == address(0)) {
            uint256 remain = MAX_SUPPLY - totalSupply();
            if (remain < quantity) {
                revert InsufficientSupply(quantity, remain);
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @notice Withdraws all sales proceeds.
     * @param to Address to which proceeds must be sent.
     */
    function withdraw(address payable to) external onlyRole(WITHDRAWAL_ROLE) {
        to.sendValue(address(this).balance);
    }

    /**
     * @notice Revokes all seller contracts, regardless of number of tokens minted.
     */
    function close() external onlyRole(DEFAULT_STEERING_ROLE) {
        _revokeAllSellers();
    }

    /**
     * @dev Required override resolution.
     */
    function _baseURI() internal view override(ERC721A, BaseTokenURI) returns (string memory) {
        return BaseTokenURI._baseURI();
    }

    /**
     * @dev Required override resolution.
     */
    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.approve(operator, tokenId);
    }

    /**
     * @dev Required override resolution.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Required override resolution.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Required override resolution.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Required override resolution.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Required override resolution.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC721ACommon, SellableERC721ACommon)
        returns (bool)
    {
        return SellableERC721ACommon.supportsInterface(interfaceId)
            || AccessControlEnumerable.supportsInterface(interfaceId);
    }
}
