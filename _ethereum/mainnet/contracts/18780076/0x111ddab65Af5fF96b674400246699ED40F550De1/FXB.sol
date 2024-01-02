// SPDX-License-Identifier: ISC
pragma solidity ^0.8.23;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =============================== FXB ================================
// ====================================================================
// Frax Bond token (FXB) ERC20 contract. A FXB is sold at a discount and redeemed 1-to-1 for FRAX at a later date.
// Frax Finance: https://github.com/FraxFinance

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./FXBFactory.sol";

/// @title FXB
/// @notice  The FXB token can be redeemed for 1 FRAX at a later date. Created via factory.
/// @dev https://github.com/FraxFinance/frax-bonds
contract FXB is ERC20, ERC20Permit {
    // =============================================================================================
    // Storage
    // =============================================================================================

    /// @notice The Frax token contract
    IERC20 public immutable FRAX;

    /// @notice Timestamp of bond maturity
    uint256 public immutable MATURITY_TIMESTAMP;

    /// @notice Total amount of FXB minted
    uint256 public totalFxbMinted;

    /// @notice Total amount of FXB redeemed
    uint256 public totalFxbRedeemed;

    // =============================================================================================
    // Structs
    // =============================================================================================

    /// @notice Bond Information
    /// @param symbol The symbol of the bond
    /// @param name The name of the bond
    /// @param maturityTimestamp Timestamp the bond will mature
    struct BondInfo {
        string symbol;
        string name;
        uint256 maturityTimestamp;
    }

    // =============================================================================================
    // Constructor
    // =============================================================================================

    /// @notice Called by the factory
    /// @param _frax The address of the FRAX token
    /// @param _symbol The symbol of the bond
    /// @param _name The name of the bond
    /// @param _maturityTimestamp Timestamp the bond will mature and be redeemable
    constructor(
        address _frax,
        string memory _symbol,
        string memory _name,
        uint256 _maturityTimestamp
    ) ERC20(_symbol, _name) ERC20Permit(_symbol) {
        // Set the FRAX address
        FRAX = IERC20(_frax);

        // Set the maturity timestamp
        MATURITY_TIMESTAMP = _maturityTimestamp;
    }

    // =============================================================================================
    // View functions
    // =============================================================================================

    /// @notice Returns summary information about the bond
    /// @return BondInfo Summary of the bond
    function bondInfo() external view returns (BondInfo memory) {
        return BondInfo({ symbol: symbol(), name: name(), maturityTimestamp: MATURITY_TIMESTAMP });
    }

    /// @notice Returns a boolean representing whether a bond can be redeemed
    /// @return _isRedeemable If the bond is redeemable
    function isRedeemable() public view returns (bool _isRedeemable) {
        _isRedeemable = (block.timestamp >= MATURITY_TIMESTAMP);
    }

    // =============================================================================================
    // Public functions
    // =============================================================================================

    /// @notice Mints a specified amount of tokens to the account, requires caller to approve on the FRAX contract in an amount equal to the minted amount
    /// @dev Supports OZ 5.0 interfacing with named variable arguments
    /// @param account The account to receive minted tokens
    /// @param value The amount of the token to mint
    function mint(address account, uint256 value) external {
        // NOTE: Allow minting after expiry

        // Make sure minting an amount
        if (value == 0) revert ZeroAmount();

        // Effects: update mint tracking
        totalFxbMinted += value;

        // Effects: Give the FXB to the recipient
        _mint({ account: account, value: value });

        // Interactions: Take 1-to-1 FRAX from the user
        FRAX.transferFrom(msg.sender, address(this), value);
    }

    /// @notice Redeems FXB 1-to-1 for FRAX
    /// @dev Supports OZ 5.0 interfacing with named variable arguments
    /// @param to Recipient of redeemed FRAX
    /// @param value Amount to redeem
    function burn(address to, uint256 value) external {
        // Make sure the bond has matured
        if (!isRedeemable()) revert BondNotRedeemable();

        // Make sure you burning a nonzero amount
        if (value == 0) revert ZeroAmount();

        // Effects: Update redeem tracking
        totalFxbRedeemed += value;

        // Effects: Burn the FXB from the user
        _burn({ account: msg.sender, value: value });

        // Interactions: Give FRAX to the recipient
        FRAX.transfer(to, value);
    }

    // ==============================================================================
    // Errors
    // ==============================================================================

    /// @notice Thrown if the bond hasn't matured yet, or redeeming is paused
    error BondNotRedeemable();

    /// @notice Thrown if attempting to mint / burn zero tokens
    error ZeroAmount();
}
