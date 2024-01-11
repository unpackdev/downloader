// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import "./ERC721ReadOnlyProxy.sol";

/// @title BaseToken for O/W tokens
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice Abstract contract integrating rentable utils
abstract contract BaseTokenInitializable is ERC721ReadOnlyProxy {
    /* ========== STATE VARIABLES ========== */
    // rentable reference
    address private _rentable;

    /* ========== MODIFIERS ========== */
    modifier onlyRentable() {
        require(_msgSender() == _rentable, "Only rentable");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    /// @notice Instantiate a token
    /// @param wrapped wrapped token address
    /// @param owner admin for the contract
    /// @param rentable rentable address
    constructor(
        address wrapped,
        address owner,
        address rentable
    ) {
        _initialize(wrapped, owner, rentable);
    }

    /* ---------- INITIALIZER ---------- */
    /// @notice Initialize a token (to be used with proxies)
    /// @param wrapped wrapped token address
    /// @param owner admin for the contract
    /// @param rentable rentable address
    function initialize(
        address wrapped,
        address owner,
        address rentable
    ) external {
        _initialize(wrapped, owner, rentable);
    }

    /// @dev Internal shared initializer
    /// @param wrapped wrapped token address
    /// @param owner admin for the contract
    /// @param rentable rentable address
    function _initialize(
        address wrapped,
        address owner,
        address rentable
    ) internal initializer {
        __ERC721ReadOnlyProxy_init(wrapped, _getPrefix(), owner);
        _setRentable(rentable);
    }

    /* ========== SETTERS ========== */

    /* ---------- Internal ---------- */

    /// @dev Set rentable address
    /// @param rentable rentable address
    function _setRentable(address rentable) internal {
        _rentable = rentable;
        _setMinter(rentable);
    }

    /* ---------- Public ---------- */

    /// @dev Set rentable address
    /// @param rentable rentable address
    function setRentable(address rentable) external onlyOwner {
        _setRentable(rentable);
    }

    /* ========== VIEWS ========== */

    /* ---------- Internal ---------- */

    /// @dev Get token prefix used during initialization (must be implemented)
    /// @return token prefix (e.g. o or w)
    function _getPrefix() internal virtual returns (string memory);

    /* ---------- Public ---------- */

    /// @notice Get rentable address
    /// @return rentable address
    function getRentable() public view returns (address) {
        return _rentable;
    }

    // Reserved storage space to allow for layout changes in the future.
    // slither-disable-next-line unused-state
    uint256[50] private _gap;
}
