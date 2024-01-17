// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20Metadata.sol";
import "./OracleHelpers.sol";
import "./IStableCoinProvider.sol";
import "./UsingStalePeriod.sol";
import "./UsingMaxDeviation.sol";

/**
 * @title Provide pegged stable coin, useful for getting USD prices reference from DEXes
 * @dev This contract mitigates a de-peg scenario by checking price against two stable coins that should be around 1
 */
contract StableCoinProvider is IStableCoinProvider, UsingStalePeriod, UsingMaxDeviation {
    using OracleHelpers for uint256;

    uint256 public constant USD_DECIMALS = 18;
    uint256 public constant ONE_USD = 10**USD_DECIMALS;

    /**
     * @notice A stable coin to use as USD price reference
     * @dev Should not be called directly from other contracts, must use `getStableCoinIfPegged`
     */
    address public primaryStableCoin;
    uint8 private __primaryStableCoinDecimals;

    /**
     * @notice A secondary stable coin used to check USD-peg against primary
     * @dev Should not be called directly from other contracts, must use `getStableCoinIfPegged`
     */
    address public secondaryStableCoin;
    uint8 private __secondaryStableCoinDecimals;

    /// @notice Emitted when stable coin is updated
    event StableCoinsUpdated(
        address oldPrimaryStableCoin,
        address oldSecondaryStableCoin,
        address newPrimaryStableCoin,
        address newSecondaryStableCoin
    );

    constructor(
        address primaryStableCoin_,
        address secondaryStableCoin_,
        uint256 stalePeriod_,
        uint256 maxDeviation_
    ) UsingStalePeriod(stalePeriod_) UsingMaxDeviation(maxDeviation_) {
        _updateStableCoins(primaryStableCoin_, secondaryStableCoin_);
    }

    /// @inheritdoc IStableCoinProvider
    function getStableCoinIfPegged() external view returns (address _stableCoin) {
        // Note: Chainlink supports DAI/USDC/USDT on all chains that we're using
        IPriceProvider _chainlink = addressProvider.providersAggregator().priceProviders(DataTypes.Provider.CHAINLINK);

        (uint256 _priceInUsd, uint256 _lastUpdatedAt) = _chainlink.getPriceInUsd(primaryStableCoin);

        if (!_priceIsStale(primaryStableCoin, _lastUpdatedAt) && _isDeviationOK(_priceInUsd, ONE_USD)) {
            return primaryStableCoin;
        }

        (_priceInUsd, _lastUpdatedAt) = _chainlink.getPriceInUsd(secondaryStableCoin);

        require(
            !_priceIsStale(secondaryStableCoin, _lastUpdatedAt) && _isDeviationOK(_priceInUsd, ONE_USD),
            "stable-prices-invalid"
        );

        return secondaryStableCoin;
    }

    /// @inheritdoc IStableCoinProvider
    function toUsdRepresentation(uint256 stableCoinAmount_) external view returns (uint256 _usdAmount) {
        uint256 _stableCoinDecimals = __primaryStableCoinDecimals;
        if (_stableCoinDecimals == USD_DECIMALS) {
            return stableCoinAmount_;
        }
        _usdAmount = stableCoinAmount_.scaleDecimal(_stableCoinDecimals, USD_DECIMALS);
    }

    /**
     * @notice Update the stable coin keeping correct decimals value
     * @dev Must have both as set or null
     */
    function _updateStableCoins(address primaryStableCoin_, address secondaryStableCoin_) private {
        require(primaryStableCoin_ != address(0) && secondaryStableCoin_ != address(0), "stable-coins-are-null");
        require(primaryStableCoin_ != secondaryStableCoin_, "stable-coins-are-the-same");

        // Update both
        primaryStableCoin = primaryStableCoin_;
        secondaryStableCoin = secondaryStableCoin_;
        __primaryStableCoinDecimals = IERC20Metadata(primaryStableCoin_).decimals();
        __secondaryStableCoinDecimals = IERC20Metadata(secondaryStableCoin_).decimals();
    }

    /**
     * @notice Update stable coin
     * @dev Used externally by the governor
     */
    function updateStableCoins(address primaryStableCoin_, address secondaryStableCoin_) external onlyGovernor {
        emit StableCoinsUpdated(primaryStableCoin, secondaryStableCoin, primaryStableCoin_, secondaryStableCoin_);
        _updateStableCoins(primaryStableCoin_, secondaryStableCoin_);
    }
}
