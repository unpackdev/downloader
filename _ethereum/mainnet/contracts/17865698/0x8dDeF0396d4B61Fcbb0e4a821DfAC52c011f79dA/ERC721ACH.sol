// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC721ACH.sol";
import "./ERC721AC.sol";
import "./IERC721A.sol";
import "./IBeforeTokenTransfersHook.sol";
import "./IAfterTokenTransfersHook.sol";
import "./IOwnerOfHook.sol";

/**
 * @title ERC721ACH
 * @author Cre8ors Inc.
 * @notice This contract extends Limit Break's ERC721-AC implementation with hook functionality.
 *  It allows the contract owner to set hooks that modify the behavior of core ERC721
 *  functions. Each hook type can be associated with a contract that implements the
 *  corresponding hook's logic. Only the contract owner can set or change these hooks.
 */
contract ERC721ACH is IERC721ACH, ERC721AC {
    /**
     * @dev This mapping associates hook types with their corresponding contract addresses.
     * Each hook type can be associated with a contract that implements the hook's logic.
     * Only the contract owner can set or change these hooks.
     */
    mapping(HookType => address) public hooks;

    /**
     * @dev Contract constructor.
     * @param _contractName The name of the token contract.
     * @param _contractSymbol The symbol of the token contract.
     */
    constructor(
        string memory _contractName,
        string memory _contractSymbol
    ) ERC721AC(_contractName, _contractSymbol) {}

    /// @inheritdoc IERC721A
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /////////////////////////////////////////////////
    /// ERC721 overrides
    /////////////////////////////////////////////////

    /**
     * @notice Before token transfer hook. This function is called before any token transfer.
     * This includes minting and burning.
     * @param from The source address.
     * @param to The destination address.
     * @param startTokenId The ID of the first token to be transferred.
     * @param quantity The number of tokens to be transferred.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        IBeforeTokenTransfersHook hook = IBeforeTokenTransfersHook(
            hooks[HookType.BeforeTokenTransfers]
        );
        if (address(hook) != address(0)) {
            hook.beforeTokenTransfersHook(from, to, startTokenId, quantity);
        }
    }

    /**
     * @notice After token transfer hook. This function is called after any token transfer.
     * This includes minting and burning.
     * @param from The source address.
     * @param to The destination address.
     * @param startTokenId The ID of the first token to be transferred.
     * @param quantity The number of tokens to be transferred.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
        IAfterTokenTransfersHook hook = IAfterTokenTransfersHook(
            hooks[HookType.AfterTokenTransfers]
        );
        if (address(hook) != address(0)) {
            hook.afterTokenTransfersHook(from, to, startTokenId, quantity);
        }
    }

    /**
     * @notice Returns the owner of the `tokenId` token.
     * @dev The owner of a token is also its approver by default.
     * @param tokenId The ID of the token to query.
     * @return owner of the `tokenId` token.
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address owner) {
        bool runSuper;
        IOwnerOfHook hook = IOwnerOfHook(hooks[HookType.OwnerOf]);

        if (address(hook) != address(0)) {
            (owner, runSuper) = hook.ownerOfHook(tokenId);
        } else {
            runSuper = true;
        }

        if (runSuper) {
            owner = super.ownerOf(tokenId);
        }
    }

    /**
     * @notice Returns the address of the contract that implements the logic for the given hook type.
     * @param hookType The type of the hook to query.
     * @return address of the contract that implements the hook's logic.
     */
    function getHook(HookType hookType) external view returns (address) {
        return hooks[hookType];
    }

    /////////////////////////////////////////////////
    /// ERC721C Override
    /////////////////////////////////////////////////

    /**
     * @notice This internal function is used to ensure that the caller is the contract owner.
     * @dev Throws if called by any account other than the owner.
     */
    function _requireCallerIsContractOwner() internal view virtual override {}

    /////////////////////////////////////////////////
    /// ERC721H Admin Controls
    /////////////////////////////////////////////////

    /**
     * @notice Updates the contract address for a specific hook type.
     * @dev Throws if called by any account other than the owner.
     * Emits a {UpdatedHook} event.
     * @param hookType The type of the hook to set.
     * @param hookAddress The address of the contract that implements the hook's logic.
     */
    function setHook(
        HookType hookType,
        address hookAddress
    ) external virtual onlyOwner {
        hooks[hookType] = hookAddress;
        emit UpdatedHook(msg.sender, hookType, hookAddress);
    }

    /**
     * @notice This modifier checks if the caller is the contract owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _requireCallerIsContractOwner();

        _;
    }
}
