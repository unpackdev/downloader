// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./AdminControl.sol";
import "./Constants.sol";
import "./StringConvertor.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IPriceOracle.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // returns a uq112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << 112) / denominator);
    }

    // decode a uq112x112 into a uint256 with 18 decimals of precision
    function decode112with18(uq112x112 memory self)
        internal
        pure
        returns (uint256)
    {
        // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
        // instead, get close to:
        //  (x * 1e18) >> 112
        // without risk of overflowing, e.g.:
        //  (x) / 2 ** (112 - lg(1e18))
        return uint256(self._x) / 5192296858534827;
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative +=
                uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
                timeElapsed;
            // counterfactual
            price1Cumulative +=
                uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
                timeElapsed;
        }
    }
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

/**
 * Only support UniswapV2 pairs with ETH or any StableCoin.
 */
contract UniswapV2PriceOracle is IPriceOracle, AdminControl {
    using FixedPoint for *;
    using SafeMathUpgradeable for *;
    using BokkyPooBahsDateTimeLibrary for uint64;

    event AddTokenConfig(
        address underlying,
        uint256 baseUnit,
        uint256 anchorUnit,
        address uniswapMarket,
        bool isStableCoinBase,
        bool isUniswapReversed
    );

    event SetPriceOracleManager(
        address oldPriceOracleManager, 
        address newPriceOracleManager
    );

    event RefreshPrice(
        address underlying,
        uint64 fromDate,
        uint64 toDate,
        uint256 fromTimestamp,
        uint256 fromTokenAcc,
        uint256 fromEthAcc,
        uint256 toTimestamp,
        uint256 toTokenAcc,
        uint256 toEthAcc,
        uint256 price
    );

    struct TokenConfig {
        uint256 baseUnit;
        uint256 anchorUnit;
        address uniswapMarket;
        bool isStableCoinBase;
        bool isUniswapReversed;
    }

    struct Observation {
        uint256 fromTimestamp;
        uint256 fromTokenAcc;
        uint256 fromEthAcc;
        uint256 toTimestamp;
        uint256 toTokenAcc;
        uint256 toEthAcc;
        uint256 price;
    }

    /// @notice A common scaling factor to maintain precision
    uint256 public constant expScale = 1e18;

    /// @notice Decimals of price value that this oracle should return
    uint256 public constant priceUnit = 1e8;

    // underlying => tokenConfig
    mapping(address => TokenConfig) public tokenConfigs;

    // underlying => datesig => Observation
    mapping(address => mapping(bytes32 => Observation)) public observations;

    address public priceOracleManager;

    modifier onlyPriceOracleManager() {
        require(msg.sender == priceOracleManager, "only priceOracleManager");
        _;
    }

    function initialize(TokenConfig calldata ethConfig) external initializer {
        AdminControl.__AdminControl_init(_msgSender());
        tokenConfigs[Constants.ETH_ADDRESS] = TokenConfig(
            ethConfig.baseUnit,
            ethConfig.anchorUnit,
            ethConfig.uniswapMarket,
            ethConfig.isStableCoinBase,
            ethConfig.isUniswapReversed
        );
    }

    function addTokenConfig(
        address underlying_,
        uint256 baseUnit_,
        uint256 anchorUnit_,
        address uniswapMarket_,
        bool isStableCoinBase_,
        bool isUniswapReversed_
    ) external onlyAdmin {
        tokenConfigs[underlying_] = (
            TokenConfig(baseUnit_, anchorUnit_, uniswapMarket_, isStableCoinBase_, isUniswapReversed_)
        );

        emit AddTokenConfig(
            underlying_, baseUnit_, anchorUnit_, uniswapMarket_, 
            isStableCoinBase_, isUniswapReversed_
        );
    }

    function refreshPrice(
        address underlying_,
        uint64 fromDate_,
        uint64 toDate_
    ) external override onlyPriceOracleManager {
        string memory fromDate = _getDateString(fromDate_);
        string memory toDate = _getDateString(toDate_);
        bytes32 dateSignature = _getDateSignature(fromDate, toDate);

        TokenConfig memory config = tokenConfigs[underlying_];
        Observation storage observation = observations[underlying_][dateSignature];
        require(
            (observation.fromTimestamp == 0 &&
                block.timestamp.sub(fromDate_) <= 86400) ||
                (observation.toTimestamp == 0 && 
                    block.timestamp > observation.fromTimestamp &&
                    block.timestamp.sub(toDate_) <= 86400),
            "non-refreshable"
        );

        if (observation.fromTimestamp == 0) {
            observation.fromTimestamp = block.timestamp;
            observation.fromTokenAcc = currentCumulativePrice(
                tokenConfigs[underlying_]
            );
            if (!config.isStableCoinBase) {
                observation.fromEthAcc = currentCumulativePrice(
                    tokenConfigs[Constants.ETH_ADDRESS]
                );
            }
            
        } else {
            observation.toTimestamp = block.timestamp;
            observation.toTokenAcc = currentCumulativePrice(
                tokenConfigs[underlying_]
            );

            // determine the final price by fromAcc and toAcc
            if (config.isStableCoinBase) {
                observation.price = calculateAveragePrice(
                    observation.fromTimestamp,
                    observation.fromTokenAcc,
                    observation.toTimestamp,
                    observation.toTokenAcc,
                    priceUnit,
                    config.baseUnit,
                    config.anchorUnit
                );

            } else {
                TokenConfig memory ethConfig = tokenConfigs[Constants.ETH_ADDRESS];
                observation.toEthAcc = currentCumulativePrice(ethConfig);

                // 1e20 is used to scale the 6-decimal USDC price to the desired 8-decimal usd price
                uint256 ethAveragePrice = calculateAveragePrice(
                    observation.fromTimestamp,
                    observation.fromEthAcc,
                    observation.toTimestamp,
                    observation.toEthAcc,
                    priceUnit,
                    ethConfig.baseUnit,
                    ethConfig.anchorUnit
                );
                observation.price = calculateAveragePrice(
                    observation.fromTimestamp,
                    observation.fromTokenAcc,
                    observation.toTimestamp,
                    observation.toTokenAcc,
                    ethAveragePrice,
                    config.baseUnit,
                    config.anchorUnit
                );
            }
        }

        emit RefreshPrice(
            underlying_, fromDate_, toDate_, 
            observation.fromTimestamp, observation.fromTokenAcc, observation.fromEthAcc,
            observation.toTimestamp, observation.toTokenAcc, observation.toEthAcc,
            observation.price
        );
    }

    function calculateAveragePrice(
        uint256 fromTimestamp_,
        uint256 fromAcc_,
        uint256 toTimestamp_,
        uint256 toAcc_,
        uint256 conversionFactor_,
        uint256 baseUnit_,
        uint256 anchorUnit_
    ) internal pure returns (uint256) {
        require(
            toTimestamp_ > fromTimestamp_ && toAcc_ > fromAcc_,
            "invalid acc values"
        );
        uint256 timeElapsed = toTimestamp_ - fromTimestamp_;

        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((toAcc_ - fromAcc_) / timeElapsed)
        );
        uint256 rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint256 unscaledPriceMantissa = rawUniswapPriceMantissa.mul(conversionFactor_);
        return unscaledPriceMantissa.mul(baseUnit_).div(anchorUnit_).div(expScale);
    }

    function currentCumulativePrice(TokenConfig memory config)
        internal
        view
        returns (uint256)
    {
        (
            uint256 cumulativePrice0,
            uint256 cumulativePrice1,
        ) = UniswapV2OracleLibrary.currentCumulativePrices(
                config.uniswapMarket
            );
        if (config.isUniswapReversed) {
            return cumulativePrice1;
        } else {
            return cumulativePrice0;
        }
    }

    function getObservation(
        address underlying_,
        uint64 fromDate_,
        uint64 toDate_
    ) external view returns (Observation memory) {
        string memory fromDate = _getDateString(fromDate_);
        string memory toDate = _getDateString(toDate_);
        bytes32 dateSignature = _getDateSignature(fromDate, toDate);
        return observations[underlying_][dateSignature];
    }

    function getPrice(
        address underlying_,
        uint64 fromDate_,
        uint64 toDate_
    ) external view override returns (int256) {
        string memory fromDate = _getDateString(fromDate_);
        string memory toDate = _getDateString(toDate_);
        bytes32 dateSignature = _getDateSignature(fromDate, toDate);
        return int256(observations[underlying_][dateSignature].price);
    }

    function setPriceOracleManager(address manager_) external onlyAdmin {
        require(manager_ != address(0), "manager can not be 0 address");
        emit SetPriceOracleManager(priceOracleManager, manager_);
        priceOracleManager = manager_;
    }

    function _getDateString(uint64 date_)
        internal
        pure
        returns (string memory)
    {
        (uint256 year, uint256 month, uint256 day) = date_.timestampToDate();
        return string(abi.encodePacked(year, "-", month, "-", day));
    }

    function _getDateSignature(string memory fromDate_, string memory toDate_)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(fromDate_, toDate_));
    }
}
