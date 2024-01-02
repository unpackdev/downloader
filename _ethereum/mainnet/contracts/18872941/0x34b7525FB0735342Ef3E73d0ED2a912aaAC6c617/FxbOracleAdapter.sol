// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FxbOracleAdapter =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// ====================================================================
import "./Timelock2Step.sol";
import "./ITimelock2Step.sol";
import "./ERC165Storage.sol";
import "./DualOracleBase.sol";
import "./IDualOracle.sol";

struct ConstructorParams {
    // = Timelock2Step
    address timelockAddress;
    // = DualOracleBase
    address baseToken0;
    uint8 baseToken0Decimals;
    address quoteToken0;
    uint8 quoteToken0Decimals;
    address baseToken1;
    uint8 baseToken1Decimals;
    address quoteToken1;
    uint8 quoteToken1Decimals;
    // = ExponentialPriceOracle
    address exponentialPriceOracle;
    string name;
}

/// @title ArbitrumDualOracle
/// @notice An oracle for the Arbitrum token in Usd terms
contract FxbOracleAdapter is ERC165Storage, DualOracleBase {
    string public name;
    IDualOracle public immutable EXPONENTIAL_RATE_ORACLE;

    constructor(
        ConstructorParams memory params
    )
        DualOracleBase(
            DualOracleBaseParams({
                baseToken0: params.baseToken0,
                baseToken0Decimals: params.baseToken0Decimals,
                quoteToken0: params.quoteToken0,
                quoteToken0Decimals: params.quoteToken0Decimals,
                baseToken1: params.baseToken1,
                baseToken1Decimals: params.baseToken1Decimals,
                quoteToken1: params.quoteToken1,
                quoteToken1Decimals: params.quoteToken1Decimals
            })
        )
    {
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        name = params.name;
        EXPONENTIAL_RATE_ORACLE = IDualOracle(params.exponentialPriceOracle);
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    /// @notice The ```getPricesNormalized``` function returns the normalized prices in human readable form
    /// @dev decimals of underlying tokens match so we can just return _getPrices()
    /// @return isBadDataNormal If the Chainlink oracle is stale
    /// @return priceLowNormal The normalized low price
    /// @return priceHighNormal The normalized high price
    function getPricesNormalized()
        external
        view
        override
        returns (bool isBadDataNormal, uint256 priceLowNormal, uint256 priceHighNormal)
    {
        (isBadDataNormal, priceLowNormal, priceHighNormal) = _getPrices();
    }

    /// @notice The ```_getPrices``` function which will ingest and format prices returned from the ```EXPONENTIAL_RATE_ORACLE```
    /// @return isBadData is true when the data is stale or otherwise bad
    /// @return priceLow is the lower of the two prices in the format of debt denominated in collateral
    /// @return priceHigh is the higher of the two prices in the format of debt denominated in collateral
    /// @dev Prices returned from the ```EXPONENTIAL_RATE_ORACLE``` are in terms of collateral denominated in debt
    function _getPrices() internal view returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        (, uint256 _priceLow, uint256 _priceHigh) = EXPONENTIAL_RATE_ORACLE.getPrices();
        priceLow = 1e36 / _priceHigh;
        priceHigh = 1e36 / _priceLow;
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return isBadData is true when data is stale or otherwise bad
    /// @return priceLow is the lower of the two prices
    /// @return priceHigh is the higher of the two prices
    function getPrices() external view returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        (isBadData, priceLow, priceHigh) = _getPrices();
    }
}
