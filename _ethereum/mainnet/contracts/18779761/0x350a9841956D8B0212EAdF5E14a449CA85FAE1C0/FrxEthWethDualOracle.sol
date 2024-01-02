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
// ======================= FrxEthWethDualOracle =======================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// ====================================================================
import "./ERC165Storage.sol";
import "./Timelock2Step.sol";
import "./ITimelock2Step.sol";
import "./DualOracleBase.sol";
import "./UniswapV3SingleTwapOracle.sol";
import "./EthUsdChainlinkOracleWithMaxDelay.sol";
import "./CurvePoolEmaPriceOracleWithMinMax.sol";
import "./FraxUsdChainlinkOracleWithMaxDelay.sol";
import "./IDualOracle.sol";
import "./IPriceSource.sol";
import "./IPriceSourceReceiver.sol";

/// @notice minimumCurvePoolEma Minimum price to return from Curve for frxEth i.e. 7e17 = .7 ether
/// @notice maximumCurvePoolEma Maximum price to return from Curve for frxEth i.e. 1e18 = 1 ether
struct ConstructorParams {
    // = DualOracleBase
    address baseToken0; // frxEth
    uint8 baseToken0Decimals;
    address quoteToken0; // weth
    uint8 quoteToken0Decimals;
    address baseToken1; // frxEth
    uint8 baseToken1Decimals;
    address quoteToken1; // weth
    uint8 quoteToken1Decimals;
    // = UniswapV3SingleTwapOracle
    address frxEthErc20;
    address fraxErc20;
    address uniV3PairAddress;
    uint32 twapDuration;
    // = FraxUsdChainlinkOracleWithMaxDelay
    address fraxUsdChainlinkFeedAddress;
    uint256 fraxUsdMaximumOracleDelay;
    // = EthUsdChainlinkOracleWithMaxDelay
    address ethUsdChainlinkFeed;
    uint256 maxEthUsdOracleDelay;
    // = CurvePoolEmaPriceOracleWithMinMax
    address curvePoolEmaPriceOracleAddress;
    uint256 minimumCurvePoolEma;
    uint256 maximumCurvePoolEma;
    // = Timelock2Step
    address timelockAddress;
}

/// @title FrxEthWethDualOracle
/// @notice This price source feeds prices to the FraxOracle system
/// @dev Returns prices of Frax assets in Ether
contract FrxEthWethDualOracle is
    DualOracleBase,
    CurvePoolEmaPriceOracleWithMinMax,
    UniswapV3SingleTwapOracle,
    FraxUsdChainlinkOracleWithMaxDelay,
    EthUsdChainlinkOracleWithMaxDelay,
    IPriceSource,
    Timelock2Step
{
    /// @notice The address of the Erc20 token contract
    address public immutable FRXETH_ERC20;

    constructor(
        ConstructorParams memory _params
    )
        DualOracleBase(
            DualOracleBaseParams({
                baseToken0: _params.baseToken0,
                baseToken0Decimals: _params.baseToken0Decimals,
                quoteToken0: _params.quoteToken0,
                quoteToken0Decimals: _params.quoteToken0Decimals,
                baseToken1: _params.baseToken1,
                baseToken1Decimals: _params.baseToken1Decimals,
                quoteToken1: _params.quoteToken1,
                quoteToken1Decimals: _params.quoteToken1Decimals
            })
        )
        CurvePoolEmaPriceOracleWithMinMax(
            CurvePoolEmaPriceOracleWithMinMaxParams({
                curvePoolEmaPriceOracleAddress: _params.curvePoolEmaPriceOracleAddress,
                minimumCurvePoolEma: _params.minimumCurvePoolEma,
                maximumCurvePoolEma: _params.maximumCurvePoolEma
            })
        )
        UniswapV3SingleTwapOracle(
            UniswapV3SingleTwapOracleParams({
                uniswapV3PairAddress: _params.uniV3PairAddress,
                twapDuration: _params.twapDuration,
                baseToken: _params.frxEthErc20,
                quoteToken: _params.fraxErc20
            })
        )
        EthUsdChainlinkOracleWithMaxDelay(
            EthUsdChainlinkOracleWithMaxDelayParams({
                ethUsdChainlinkFeedAddress: _params.ethUsdChainlinkFeed,
                maxEthUsdOracleDelay: _params.maxEthUsdOracleDelay
            })
        )
        FraxUsdChainlinkOracleWithMaxDelay(
            FraxUsdChainlinkOracleWithMaxDelayParams({
                fraxUsdChainlinkFeedAddress: _params.fraxUsdChainlinkFeedAddress,
                fraxUsdMaximumOracleDelay: _params.fraxUsdMaximumOracleDelay
            })
        )
        Timelock2Step()
    {
        _setTimelock({ _newTimelock: _params.timelockAddress });
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });
        _registerInterface({ interfaceId: type(IPriceSource).interfaceId });

        FRXETH_ERC20 = _params.frxEthErc20;
    }

    // ====================================================================
    // Metadata
    // ====================================================================

    /// @notice The ```name``` function returns the name of the contract
    /// @return _name The name of the contract
    function name() external pure virtual returns (string memory _name) {
        _name = "frxEth Dual Oracle In Weth with Curve Pool EMA and Uniswap v3 TWAP and Frax and ETH Chainlink";
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMinimumCurvePoolEma``` function sets the minimum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param _minimumPrice The minimum price of frxEth in Ether units of the EMA
    function setMinimumCurvePoolEma(uint256 _minimumPrice) external override {
        _requireTimelock();
        _setMinimumCurvePoolEma({ _minimumPrice: _minimumPrice });
    }

    /// @notice The ```setMaximumCurvePoolEma``` function sets the maximum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param _maximumPrice The maximum price of frxEth in Ether units of the EMA
    function setMaximumCurvePoolEma(uint256 _maximumPrice) external override {
        _requireTimelock();
        _setMaximumCurvePoolEma({ _maximumPrice: _maximumPrice });
    }

    /// @notice The ```setTwapDuration``` function sets the TWAP duration for the Uniswap V3 oracle
    /// @dev Must be called by the timelock
    /// @param _newTwapDuration The new TWAP duration
    function setTwapDuration(uint32 _newTwapDuration) external override {
        _requireTimelock();
        _setTwapDuration({ _newTwapDuration: _newTwapDuration });
    }

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumEthUsdOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    /// @notice The ```setMaximumFraxUsdOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Must be called by the timelock
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumFraxUsdOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    // ====================================================================
    // Price Source Function
    // ====================================================================

    /// @notice The ```addRoundData``` adds new price data to a FraxOracle
    /// @dev This contract must be whitelisted on the receiver address
    /// @param _fraxOracle Address of a FraxOracle that has this contract set as its priceSource
    function addRoundData(IPriceSourceReceiver _fraxOracle) external {
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = _getPrices();
        // Authorization is handled on fraxOracle side
        _fraxOracle.addRoundData({
            isBadData: _isBadData,
            priceLow: uint104(_priceLow),
            priceHigh: uint104(_priceHigh),
            timestamp: uint40(block.timestamp)
        });
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    /// @notice The ```getCurveEmaEthPerFrxEth``` function gets the EMA price of frxEth in eth units
    /// @dev normalized to match precision of oracle
    /// @return _ethPerFrxEth
    function getCurveEmaEthPerFrxEth() public view returns (uint256 _ethPerFrxEth) {
        _ethPerFrxEth = _getCurvePoolToken1EmaPrice();

        // Note: ORACLE_PRECISION == CURVE_POOL_EMA_PRICE_ORACLE_PRECISION
        // _ethPerFrxEth = (ORACLE_PRECISION * _getCurvePoolToken1EmaPrice()) / CURVE_POOL_EMA_PRICE_ORACLE_PRECISION;
    }

    /// @notice The ```getChainlinkUsdPerFrax``` function gets the Chainlink price of frax in usd units
    /// @dev normalized to match precision of oracle
    /// @return _isBadData Whether the Chainlink data is stale
    /// @return _usdPerFrax
    function getChainlinkUsdPerFrax() public view returns (bool _isBadData, uint256 _usdPerFrax) {
        (bool _isBadDataChainlink, , uint256 _usdPerFraxRaw) = _getFraxUsdChainlinkPrice();

        // Set return values
        _isBadData = _isBadDataChainlink;
        _usdPerFrax = (ORACLE_PRECISION * _usdPerFraxRaw) / FRAX_USD_CHAINLINK_FEED_PRECISION;
    }

    /// @notice The ```getUsdPerEthChainlink``` function returns USD per ETH using the Chainlink oracle
    /// @return _isBadData If the Chainlink oracle is stale
    /// @return _usdPerEth The Eth Price is usd units
    function getUsdPerEthChainlink() public view returns (bool _isBadData, uint256 _usdPerEth) {
        uint256 _usdPerEthChainlinkRaw;
        (_isBadData, , _usdPerEthChainlinkRaw) = _getEthUsdChainlinkPrice();
        _usdPerEth = (ORACLE_PRECISION * _usdPerEthChainlinkRaw) / ETH_USD_CHAINLINK_FEED_PRECISION;
    }

    function _calculatePrices(
        uint256 _ethPerFrxEthCurveEma,
        uint256 _fraxPerFrxEthTwap,
        bool _isBadDataEthUsdChainlink,
        uint256 _usdPerEthChainlink,
        bool _isBadDataFraxUsdChainlink,
        uint256 _usdPerFraxChainlink
    ) internal view virtual returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 _ethPerFrxEthRawTwap = (_fraxPerFrxEthTwap * _usdPerFraxChainlink) / _usdPerEthChainlink;

        uint256 _maximumCurvePoolEma = maximumCurvePoolEma;
        uint256 _minimumCurvePoolEma = minimumCurvePoolEma;

        // Bound uniswap twap + chainlink price to same price min/max constraints as the curvePoolEma
        uint256 twapEthPerFrxEthHighBounded = _ethPerFrxEthRawTwap > _maximumCurvePoolEma
            ? _maximumCurvePoolEma
            : _ethPerFrxEthRawTwap;

        uint256 twapEthPerFrxEth = twapEthPerFrxEthHighBounded < _minimumCurvePoolEma
            ? _minimumCurvePoolEma
            : twapEthPerFrxEthHighBounded;

        _isBadData = _isBadDataEthUsdChainlink || _isBadDataFraxUsdChainlink;
        _priceLow = _ethPerFrxEthCurveEma < twapEthPerFrxEth ? _ethPerFrxEthCurveEma : twapEthPerFrxEth;
        _priceHigh = twapEthPerFrxEth > _ethPerFrxEthCurveEma ? twapEthPerFrxEth : _ethPerFrxEthCurveEma;
    }

    /// @notice The ```calculatePrices``` function calculates the normalized prices in a pure function
    /// @return _isBadData True if any of the oracles return stale data
    /// @return _priceLow The normalized low price
    /// @return _priceHigh The normalized high price
    function calculatePrices(
        uint256 _ethPerFrxEthCurveEma,
        uint256 _fraxPerFrxEthTwap,
        bool _isBadDataEthUsdChainlink,
        uint256 _usdPerEthChainlink,
        bool _isBadDataFraxUsdChainlink,
        uint256 _usdPerFraxChainlink
    ) external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (_isBadData, _priceLow, _priceHigh) = _calculatePrices({
            _ethPerFrxEthCurveEma: _ethPerFrxEthCurveEma,
            _fraxPerFrxEthTwap: _fraxPerFrxEthTwap,
            _isBadDataEthUsdChainlink: _isBadDataEthUsdChainlink,
            _usdPerEthChainlink: _usdPerEthChainlink,
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink
        });
    }

    function _getPrices() internal view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        // first price
        uint256 _ethPerFrxEthCurveEma = getCurveEmaEthPerFrxEth();

        // second price
        uint256 _fraxPerFrxEthTwap = _getUniswapV3Twap();
        (bool _isBadDataEthUsdChainlink, uint256 _usdPerEthChainlink) = getUsdPerEthChainlink();
        (bool _isBadDataFraxUsdChainlink, uint256 _usdPerFraxChainlink) = getChainlinkUsdPerFrax();

        (_isBadData, _priceLow, _priceHigh) = _calculatePrices({
            _ethPerFrxEthCurveEma: _ethPerFrxEthCurveEma,
            _fraxPerFrxEthTwap: _fraxPerFrxEthTwap,
            _isBadDataEthUsdChainlink: _isBadDataEthUsdChainlink,
            _usdPerEthChainlink: _usdPerEthChainlink,
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink
        });
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return _isBadData is true when data is stale or otherwise bad
    /// @return _priceLow is the lower of the two prices
    /// @return _priceHigh is the higher of the two prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (_isBadData, _priceLow, _priceHigh) = _getPrices();
    }

    /// @notice The ```getPricesNormalized``` function returns the normalized prices in human readable form
    /// @dev decimals of underlying tokens match so we can just return _getPrices()
    /// @return _isBadDataNormal If the oracle is stale
    /// @return _priceLowNormal The normalized low price
    /// @return _priceHighNormal The normalized high price
    function getPricesNormalized()
        external
        view
        override
        returns (bool _isBadDataNormal, uint256 _priceLowNormal, uint256 _priceHighNormal)
    {
        (_isBadDataNormal, _priceLowNormal, _priceHighNormal) = _getPrices();
    }
}
