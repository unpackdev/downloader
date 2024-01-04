// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <council@enzyme.finance>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.5.17;

/// @title ComptrollerLib Contract
/// @author Enzyme Council <security@enzyme.finance>
/// @notice The core logic library shared by all funds
interface ComptrollerLib {
    ////////////////
    // ACCOUNTING //
    ////////////////

    /// @notice Calculates the gross value of 1 unit of shares in the fund's denomination asset
    /// @param _requireFinality True if all assets must have exact final balances settled
    /// @return grossShareValue_ The amount of the denomination asset per share
    /// @return isValid_ True if the conversion rates to derive the value are all valid
    /// @dev Does not account for any fees outstanding.
    function calcGrossShareValue(bool _requireFinality)
        external
        returns (uint256 grossShareValue_, bool isValid_);

    ///////////////////
    // PARTICIPATION //
    ///////////////////

    // BUY SHARES

    /// @notice Buys shares in the fund for multiple sets of criteria
    /// @param _buyers The accounts for which to buy shares
    /// @param _investmentAmounts The amounts of the fund's denomination asset
    /// with which to buy shares for the corresponding _buyers
    /// @param _minSharesQuantities The minimum quantities of shares to buy
    /// with the corresponding _investmentAmounts
    /// @return sharesReceivedAmounts_ The actual amounts of shares received
    /// by the corresponding _buyers
    /// @dev Param arrays have indexes corresponding to individual __buyShares() orders.
    function buyShares(
        address[] calldata _buyers,
        uint256[] calldata _investmentAmounts,
        uint256[] calldata _minSharesQuantities
    ) external returns (uint256[] memory sharesReceivedAmounts_);

    // REDEEM SHARES

    /// @notice Redeem all of the sender's shares for a proportionate slice of the fund's assets
    /// @return payoutAssets_ The assets paid out to the redeemer
    /// @return payoutAmounts_ The amount of each asset paid out to the redeemer
    /// @dev See __redeemShares() for further detail
    function redeemShares()
        external
        returns (address[] memory payoutAssets_, uint256[] memory payoutAmounts_);

    /// @notice Redeem a specified quantity of the sender's shares for a proportionate slice of
    /// the fund's assets, optionally specifying additional assets and assets to skip.
    /// @param _sharesQuantity The quantity of shares to redeem
    /// @param _additionalAssets Additional (non-tracked) assets to claim
    /// @param _assetsToSkip Tracked assets to forfeit
    /// @return payoutAssets_ The assets paid out to the redeemer
    /// @return payoutAmounts_ The amount of each asset paid out to the redeemer
    /// @dev Any claim to passed _assetsToSkip will be forfeited entirely. This should generally
    /// only be exercised if a bad asset is causing redemption to fail.
    function redeemSharesDetailed(
        uint256 _sharesQuantity,
        address[] calldata _additionalAssets,
        address[] calldata _assetsToSkip
    )
        external
        returns (address[] memory payoutAssets_, uint256[] memory payoutAmounts_);

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `vaultProxy` variable
    /// @return vaultProxy_ The `vaultProxy` variable value
    function getVaultProxy() external view returns (address vaultProxy_);
}
