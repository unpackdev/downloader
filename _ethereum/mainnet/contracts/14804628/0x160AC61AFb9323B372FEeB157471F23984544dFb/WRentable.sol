// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import "./IERC721ExistExtension.sol";
import "./BaseTokenInitializable.sol";

// References
import "./IERC721Upgradeable.sol";
import "./IRentable.sol";
import "./IWRentableHooks.sol";

import "./ERC721Upgradeable.sol";

/// @title WToken
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice Represents a transferrable tokenized rental and mimics the wrapped token
contract WRentable is IERC721ExistExtension, BaseTokenInitializable {
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
        return "w";
    }

    /// @dev Check ownership eventually skipping expire check
    /// @param tokenId token id
    /// @param skipExpirationCheck when true, return current owner skipping expire check
    /// @return owner address
    function _ownerOf(uint256 tokenId, bool skipExpirationCheck)
        internal
        view
        returns (address)
    {
        // Eventually check rental expiration
        if (
            skipExpirationCheck ||
            !IRentable(getRentable()).isExpired(getWrapped(), tokenId)
        ) {
            return super.ownerOf(tokenId);
        } else {
            return address(0);
        }
    }

    /* ---------- Public ---------- */

    /// @inheritdoc IERC721Upgradeable
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownerOf(tokenId, false);
    }

    /// @inheritdoc IERC721ExistExtension
    function ownerOf(uint256 tokenId, bool skipExpirationCheck)
        external
        view
        override
        returns (address)
    {
        return _ownerOf(tokenId, skipExpirationCheck);
    }

    /// @inheritdoc IERC721ExistExtension
    function exists(uint256 tokenId) external view override returns (bool) {
        return super._exists(tokenId);
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
        IWRentableHooks(getRentable()).afterWTokenTransfer(
            getWrapped(),
            from,
            to,
            tokenId
        );
    }
}
