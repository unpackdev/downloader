// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155URIStorage.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Error.sol";

/// @title KeyUniverse1
/// @notice Keys in Spacebar serve as unique assets earned through a variety of achievements at Spacebar.
/// These achievements represent contributions and actions that you make to enhance the Spacebar community.
/// Keys, therefore, act as credentials, showcasing your involvement and commitment to the Spacebar.
/// @dev Keys are non-transferable soulbound tokens based on ERC1155.
contract KeyUniverse1 is ERC1155URIStorage, Ownable, AccessControl, Error {
    /* ============ Variables ============ */

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /* ============ Constructor ============ */

    constructor(
        address defaultAdmin,
        address operator,
        address minter
    ) ERC1155("") {
        // default uri is unnecessary
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(OPERATOR_ROLE, operator);
        _grantRole(MINTER_ROLE, minter);
        transferOwnership(defaultAdmin); // this is for OpenSea's collection admin
        _setBaseURI("ipfs://");
    }

    /* ============ Minter Functions ============ */

    /// @dev User can mint only once per tokenId
    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        if (balanceOf(to, tokenId) != 0) {
            revert TokenAlreadyMinted();
        }
        if (bytes(uri(tokenId)).length == 0) {
            revert OnlyExistingToken();
        }
        _mint(to, tokenId, 1, "");
    }

    /// @dev Mints one by one in order to prevent minting duplicate tokenIds
    function mintBatch(
        address to,
        uint256[] memory ids
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            mint(to, ids[i]);
        }
    }

    /* ============ Operator Functions ============ */

    /// @dev URI must be set before minting
    function setURIs(
        uint256[] memory tokenIds,
        string[] memory tokenURIs
    ) public onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setURI(tokenIds[i], tokenURIs[i]);
        }
    }

    // If user abuses the system, the operator can burn
    function burn(
        address account,
        uint256 tokenId
    ) public onlyRole(OPERATOR_ROLE) {
        _burn(account, tokenId, 1);
    }

    /// @dev This function is not implemented.
    function setApprovalForAll(address, bool) public virtual override {
        revert CanNotApprove();
    }

    /// @dev This function is not implemented.
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override {
        revert CanNotTransfer();
    }

    /// @dev This function is not implemented.
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override {
        revert CanNotTransfer();
    }

    /* ============ ERC-165 ============ */

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
