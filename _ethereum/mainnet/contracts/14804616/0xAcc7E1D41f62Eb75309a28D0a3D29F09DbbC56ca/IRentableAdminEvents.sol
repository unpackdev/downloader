// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title Rentable protocol admin events
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
interface IRentableAdminEvents {
    /* ========== EVENTS ========== */

    /// @notice Emitted on library change
    /// @param tokenAddress respective token address
    /// @param previousValue previous library address
    /// @param newValue new library address
    event LibraryChanged(
        address indexed tokenAddress,
        address indexed previousValue,
        address indexed newValue
    );

    /// @notice Emitted on ORentable change
    /// @param tokenAddress respective token address
    /// @param previousValue previous orentable address
    /// @param newValue new orentable address
    event ORentableChanged(
        address indexed tokenAddress,
        address indexed previousValue,
        address indexed newValue
    );

    /// @notice Emitted on WRentable change
    /// @param tokenAddress respective token address
    /// @param previousValue previous wrentable address
    /// @param newValue new wrentable address
    event WRentableChanged(
        address indexed tokenAddress,
        address indexed previousValue,
        address indexed newValue
    );

    /// @notice Emitted on WalletFactory change
    /// @param previousWalletFactory previous wallet factory address
    /// @param newWalletFactory new wallet factory address
    event WalletFactoryChanged(
        address indexed previousWalletFactory,
        address indexed newWalletFactory
    );

    /// @notice Emitted on fee change
    /// @param previousFee previous fee
    /// @param newFee new fee
    event FeeChanged(uint16 indexed previousFee, uint16 indexed newFee);

    /// @notice Emitted on fee collector change
    /// @param previousFeeCollector previous fee
    /// @param newFeeCollector new fee
    event FeeCollectorChanged(
        address indexed previousFeeCollector,
        address indexed newFeeCollector
    );

    /// @notice Emitted on payment token allowlist change
    /// @param paymentToken payment token address
    /// @param previousStatus previous allowlist status
    /// @param newStatus new allowlist status
    event PaymentTokenAllowListChanged(
        address indexed paymentToken,
        uint8 indexed previousStatus,
        uint8 indexed newStatus
    );

    /// @notice Emitted on proxy call allowlist change
    /// @param caller o/w token address
    /// @param selector selector bytes on the target wrapped token
    /// @param previousStatus previous status
    /// @param newStatus new status
    event ProxyCallAllowListChanged(
        address indexed caller,
        bytes4 selector,
        bool previousStatus,
        bool newStatus
    );
}
