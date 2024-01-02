// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "./Ownable.sol";
import "./LibClone.sol";
import "./SafeTransferLib.sol";

struct PoolSettings {
    address asset;
    address share;
    address creator;
    uint88 virtualAssets;
    uint88 virtualShares;
    uint88 maxSharePrice;
    uint88 maxSharesOut;
    uint88 maxAssetsIn;
    uint64 weightStart;
    uint64 weightEnd;
    uint40 saleStart;
    uint40 saleEnd;
    uint40 vestCliff;
    uint40 vestEnd;
    bool sellingAllowed;
    bytes32 whitelistMerkleRoot;
}

struct FactorySettings {
    address feeRecipient;
    uint48 platformFee;
    uint48 referrerFee;
    uint48 swapFee;
}

uint256 constant MAX_FEE_BIPS = 0.1e4;

contract LiquidityBootstrapPoolFactory is Ownable {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using LibClone for *;

    using SafeTransferLib for *;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emitted when a new Liquidity Bootstrap Pool is created.
    /// @param pool The address of the newly created Liquidity Bootstrap Pool.
    event PoolCreated(address pool);

    /// @dev Emitted when the fee recipient address is updated.
    /// @param recipient The new fee recipient address.
    event FeeRecipientSet(address recipient);

    /// @dev Emitted when the platform fee is updated.
    /// @param fee The new platform fee value.
    event PlatformFeeSet(uint256 fee);

    /// @dev Emitted when the referrer fee is updated.
    /// @param fee The new referrer fee value.
    event ReferrerFeeSet(uint256 fee);

    /// @dev Emitted when the swap fee is updated.
    /// @param fee The new swap fee value.
    event SwapFeeSet(uint256 fee);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @dev Error thrown when the maximum fee is exceeded.
    error MaxFeeExceeded();

    /// @dev Error thrown when the sale period is too low.
    error SalePeriodLow();

    /// @dev Error thrown when the weight config is not correct.
    error InvalidWeightConfig();

    /// @dev Error thrown when the asset or share address is invalid.
    error InvalidAssetOrShare();

    /// @dev Error thrown when the asset value is 0.
    error InvalidAssetValue();

    /// @dev Error thrown when the vestCliff is less than saleEnd.
    error InvalidVestCliff();

    /// @dev Error thrown when the vestCliff is greater or equal to vestEnd.
    error InvalidVestEnd();

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    /// @notice Storage for factory-specific settings.
    FactorySettings public factorySettings;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    /// @dev Immutable storage for the implementation address of Liquidity Bootstrap Pools.
    address internal immutable implementation;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    /// @param _implementation The address of the Liquidity Bootstrap Pool implementation contract.
    /// @param _owner The owner of the factory contract.
    /// @param _feeRecipient The address that will receive platform and referrer fees.
    /// @param _platformFee The platform fee, represented as a fraction with a denominator of 10,000.
    /// @param _referrerFee The referrer fee, represented as a fraction with a denominator of 10,000.
    /// @param _swapFee The referrer fee, represented as a fraction with a denominator of 10,000.
    constructor(
        address _implementation,
        address _owner,
        address _feeRecipient,
        uint48 _platformFee,
        uint48 _referrerFee,
        uint48 _swapFee
    ) {
        // Check that the platform and referrer fees are within the allowed range.
        if (_platformFee > MAX_FEE_BIPS) revert MaxFeeExceeded();
        if (_referrerFee > MAX_FEE_BIPS) revert MaxFeeExceeded();
        if (_swapFee > MAX_FEE_BIPS) revert MaxFeeExceeded();

        // Initialize the owner and implementation address.
        _initializeOwner(_owner);
        implementation = _implementation;

        // Set the initial factory settings including fee recipient and fees.
        factorySettings = FactorySettings(_feeRecipient, _platformFee, _referrerFee, _swapFee);

        // Emit events for the initial fee settings.
        emit FeeRecipientSet(_feeRecipient);
        emit PlatformFeeSet(_platformFee);
        emit ReferrerFeeSet(_referrerFee);
        emit SwapFeeSet(_swapFee);
    }

    /// -----------------------------------------------------------------------
    /// Creation Logic
    /// -----------------------------------------------------------------------

    /// @notice Creates a new Liquidity Bootstrap Pool with the provided settings and parameters.
    /// @param args The PoolSettings struct containing pool-specific parameters.
    /// @param shares The number of shares to transfer to the newly created pool.
    /// @param salt The salt value for deterministic pool creation.
    /// @return pool The address of the newly created Liquidity Bootstrap Pool.
    function createLiquidityBootstrapPool(
        PoolSettings memory args,
        uint256 shares,
        uint256 assets,
        bytes32 salt
    )
        external
        virtual
        returns (address pool)
    {
        if (args.share == args.asset || args.share == address(0) || args.asset == address(0)) {
            revert InvalidAssetOrShare();
        }

        // Check timestamps to ensure the sale will not immediately end.
        if (
            uint40(block.timestamp + 1 days) > args.saleEnd
                || args.saleEnd - args.saleStart < uint40(1 days)
        ) {
            revert SalePeriodLow();
        }

        // Vesting must start after the sale ends.
        if (args.saleEnd < args.vestEnd) {
            if (args.saleEnd > args.vestCliff) {
                revert InvalidVestCliff();
            }

            if (args.vestCliff >= args.vestEnd) {
                revert InvalidVestEnd();
            }
        }

        if (
            args.weightStart < 0.01 ether || args.weightStart > 0.99 ether
                || args.weightEnd > 0.99 ether || args.weightEnd < 0.01 ether
        ) {
            revert InvalidWeightConfig();
        }

        if (assets == 0 && args.virtualAssets == 0) revert InvalidAssetValue();

        pool = implementation.cloneDeterministic(_encodeImmutableArgs(args), salt);

        args.share.safeTransferFrom(msg.sender, pool, shares);
        args.asset.safeTransferFrom(msg.sender, pool, assets);

        emit PoolCreated(pool);
    }

    /// -----------------------------------------------------------------------
    /// Settings Modification Logic
    /// -----------------------------------------------------------------------

    /// @notice Sets the fee recipient address.
    /// @param recipient The new fee recipient address.
    function setFeeRecipient(address recipient) external virtual onlyOwner {
        factorySettings.feeRecipient = recipient;

        emit FeeRecipientSet(recipient);
    }

    /// @notice Sets the platform fee percentage.
    /// @param fee The new platform fee value, represented as a fraction with a denominator of 10,000.
    function setPlatformFee(uint48 fee) external virtual onlyOwner {
        if (fee > MAX_FEE_BIPS) revert MaxFeeExceeded();

        factorySettings.platformFee = fee;

        emit PlatformFeeSet(fee);
    }

    /// @notice Sets the referrer fee percentage.
    /// @param fee The new referrer fee value, represented as a fraction with a denominator of 10,000.
    function setReferrerFee(uint48 fee) external virtual onlyOwner {
        if (fee > MAX_FEE_BIPS) revert MaxFeeExceeded();

        factorySettings.referrerFee = fee;

        emit ReferrerFeeSet(fee);
    }

    /// @notice Sets the swap fee percentage.
    /// @param fee The new swap fee value, represented as a fraction with a denominator of 10,000.
    function setSwapFee(uint48 fee) external virtual onlyOwner {
        if (fee > MAX_FEE_BIPS) revert MaxFeeExceeded();

        factorySettings.swapFee = fee;

        emit SwapFeeSet(fee);
    }

    /// @notice Modifies multiple factory settings at once.
    /// @param feeRecipient The new fee recipient address.
    /// @param platformFee The new platform fee value, represented as a fraction with a denominator of 10,000.
    /// @param referrerFee The new referrer fee value, represented as a fraction with a denominator of 10,000.
    /// @param swapFee The new swap fee value, represented as a fraction with a denominator of 10,000.
    function modifySettings(
        address feeRecipient,
        uint48 platformFee,
        uint48 referrerFee,
        uint48 swapFee
    )
        external
        virtual
        onlyOwner
    {
        if (platformFee > MAX_FEE_BIPS) revert MaxFeeExceeded();
        if (referrerFee > MAX_FEE_BIPS) revert MaxFeeExceeded();
        if (swapFee > MAX_FEE_BIPS) revert MaxFeeExceeded();

        factorySettings = FactorySettings(feeRecipient, platformFee, referrerFee, swapFee);

        emit FeeRecipientSet(feeRecipient);
        emit PlatformFeeSet(platformFee);
        emit ReferrerFeeSet(referrerFee);
        emit SwapFeeSet(swapFee);
    }

    /// -----------------------------------------------------------------------
    /// Factory Helper Logic
    /// -----------------------------------------------------------------------

    /// @notice Predicts the deterministic address of a Liquidity Bootstrap Pool.
    /// @param args The PoolSettings struct containing pool-specific parameters.
    /// @param salt The salt value for deterministic pool creation.
    /// @return The deterministic address of the pool.
    function predictDeterministicAddress(
        PoolSettings memory args,
        bytes32 salt
    )
        external
        view
        virtual
        returns (address)
    {
        return implementation.predictDeterministicAddress(
            _encodeImmutableArgs(args), salt, address(this)
        );
    }

    /// @notice Predicts the init code hash for a Liquidity Bootstrap Pool.
    /// @param args The PoolSettings struct containing pool-specific parameters.
    /// @return The init code hash of the pool.
    function predictInitCodeHash(PoolSettings memory args)
        external
        view
        virtual
        returns (bytes32)
    {
        return implementation.initCodeHash(_encodeImmutableArgs(args));
    }

    function _encodeImmutableArgs(PoolSettings memory args)
        internal
        view
        virtual
        returns (bytes memory)
    {
        FactorySettings memory settings = factorySettings;
        unchecked {
            return abi.encodePacked(
                // forgefmt: disable-start
                abi.encodePacked(
                    args.asset,
                    args.share,
                    settings.feeRecipient,
                    args.creator
                ),
                abi.encodePacked(
                    args.virtualAssets,
                    args.virtualShares,
                    args.maxSharePrice,
                    args.maxSharesOut,
                    args.maxAssetsIn
                ),
                abi.encodePacked(
                    uint64(settings.platformFee) * 1e14,
                    uint64(settings.referrerFee) * 1e14,
                    args.weightStart,
                    args.weightEnd
                ),
                abi.encodePacked(
                    args.saleStart,
                    args.saleEnd
                ),
                abi.encodePacked(
                    args.vestCliff,
                    args.vestEnd,
                    uint64(settings.swapFee) * 1e14
                ),
                abi.encodePacked(
                    args.sellingAllowed,
                    args.whitelistMerkleRoot
                )
            );// forgefmt: disable-end
        }
    }
}
