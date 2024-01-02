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
// ======================= SfrxEthWethDualOracle =======================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// ====================================================================
import "./FrxEthWethDualOracle.sol";
import "./ISfrxEth.sol";

struct ConstructorParams {
    FrxEthWethDualOracleParams frxEthWethDualOracleParams;
    address sfrxEthErc4626;
}

contract SfrxEthWethDualOracle is FrxEthWethDualOracle {
    /// @notice The address of the Erc20 token contract
    ISfrxEth public immutable SFRXETH_ERC4626;

    constructor(ConstructorParams memory _params) FrxEthWethDualOracle(_params.frxEthWethDualOracleParams) {
        SFRXETH_ERC4626 = ISfrxEth(_params.sfrxEthErc4626);
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    function name() external pure override returns (string memory _name) {
        _name = "sfrxEth Dual Oracle In Weth with Curve Pool EMA and Uniswap v3 TWAP and Frax and ETH Chainlink";
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    function _calculatePrices(
        uint256 _ethPerFrxEthCurveEma,
        uint256 _fraxPerFrxEthTwap,
        bool _isBadDataEthUsdChainlink,
        uint256 _usdPerEthChainlink,
        bool _isBadDataFraxUsdChainlink,
        uint256 _usdPerFraxChainlink
    ) internal view override returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (_isBadData, _priceLow, _priceHigh) = super._calculatePrices({
            _ethPerFrxEthCurveEma: _ethPerFrxEthCurveEma,
            _fraxPerFrxEthTwap: _fraxPerFrxEthTwap,
            _isBadDataEthUsdChainlink: _isBadDataEthUsdChainlink,
            _usdPerEthChainlink: _usdPerEthChainlink,
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink
        });

        uint256 _sfrxEthPricePerShare = SFRXETH_ERC4626.pricePerShare();

        _priceLow = (_sfrxEthPricePerShare * _priceLow) / ORACLE_PRECISION;
        _priceHigh = (_sfrxEthPricePerShare * _priceHigh) / ORACLE_PRECISION;
    }
}
