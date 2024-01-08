// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

/// @title Interface for tBTC v1 Risk Manager
/// @notice Risk Manager is a smart contract with the exclusive right to claim
///         coverage from the coverage pool. Demanding coverage is akin to
///         filing a claim in traditional insurance and processing your own
///         claim. The risk manager holds an incredibly privileged position,
///         because the ability to claim coverage of an arbitrarily large
///         position could bankrupt the coverage pool.
///         tBTC v1 risk manager demands coverage by opening an auction for TBTC
///         and liquidating portion of the coverage pool when tBTC v1 deposit is
///         in liquidation and signer bonds on offer reached the specific
///         threshold. In practice, it means no one is willing to purchase
///         signer bonds for that deposit on tBTC side.
interface IRiskManagerV1 {
    /// @notice Notifies the risk manager about tBTC deposit in liquidation
    ///         state for which signer bonds on offer passed the threshold
    ///         expected by the risk manager. In practice, it means no one else
    ///         is willing to purchase signer bonds from that deposit so the
    ///         risk manager should open an auction to collect TBTC and purchase
    ///         those bonds liquidating part of the coverage pool. If there is
    ///         enough TBTC surplus from earlier auctions accumulated by the
    ///         risk manager, bonds are purchased right away without opening an
    ///         auction. Notifier calling this function receives a share in the
    ///         coverage pool as a reward - underwriter tokens are transferred
    ///         to the notifier's address.
    /// @param  depositAddress liquidating tBTC deposit address
    function notifyLiquidation(address depositAddress) external;

    /// @notice Notifies the risk manager about tBTC deposit liquidated outside
    ///         the coverage pool for which the risk manager opened an auction
    ///         earlier (as a result of `notifyLiquidation` call). Function
    ///         closes the auction early and collects TBTC surplus from the
    ///         auction in case the auction was partially taken before the
    ///         deposit got liquidated. Notifier calling this function receives
    ///         a share in the coverage pool as a reward - underwriter tokens
    ///         are transferred to the notifier's address.
    /// @param  depositAddress liquidated tBTC Deposit address
    function notifyLiquidated(address depositAddress) external;

    /// @notice Withdraws the given amount of accumulated signer bonds.
    /// @dev Usually used by `ISignerBondsSwapStrategy` implementations.
    /// @param amount Amount of signer bonds being withdrawn.
    function withdrawSignerBonds(uint256 amount) external;

    /// @notice Returns true if there are open auctions managed by the risk
    ///         manager. Returns false otherwise.
    /// @dev Usually used by `ISignerBondsSwapStrategy` implementations.
    function hasOpenAuctions() external view returns (bool);
}
