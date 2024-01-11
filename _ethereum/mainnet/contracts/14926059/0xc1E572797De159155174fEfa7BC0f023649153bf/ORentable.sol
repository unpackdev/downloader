// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import "./BaseTokenInitializable.sol";

// References
import "./IORentableHooks.sol";
import "./ERC721Upgradeable.sol";

/// @title OToken
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice Represents a transferrable tokenized deposit and mimics the wrapped token
contract ORentable is BaseTokenInitializable {
    /* ========== CONSTRUCTOR ========== */

    /// @notice Instantiate a token
    /// @param wrapped wrapped token address
    /// @param owner admin for the contract
    /// @param rentable rentable address
    constructor(
        address wrapped,
        address owner,
        address rentable
    ) BaseTokenInitializable(wrapped, owner, rentable) {}

    /* ========== VIEWS ========== */

    /* ---------- Internal ---------- */
    /// @inheritdoc BaseTokenInitializable
    function _getPrefix() internal virtual override returns (string memory) {
        return "o";
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Internal ---------- */

    /// @inheritdoc ERC721Upgradeable
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Notify Rentable after successful transfer
        super._transfer(from, to, tokenId);
        IORentableHooks(getRentable()).afterOTokenTransfer(
            getWrapped(),
            from,
            to,
            tokenId
        );
    }
}
