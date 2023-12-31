// SPDX-License-Identifier: MIT
/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */
pragma solidity ^0.8.0;

import "./IUniswapV3Pool.sol";
import "./FixedPoint96.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable2Step.sol";

import "./IERC20Metadata.sol";

import "./ICrvPool.sol";
import "./IOracleStruct.sol";

import "./TickMath.sol";

contract CvgOracle is Ownable2Step {
    /// @dev Tokens WL into oracle
    mapping(address => IOracleStruct.OracleParams) public oracleParametersPerERC20;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public cvg;

    uint256 constant ONE_ETH = 10 ** 18;
    uint256 constant TEN_36 = 10 ** 36;

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            CONSTRUCTOR
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    constructor(address treasuryDao) {
        /// @dev Transfer ownership to multisig
        _transferOwnership(treasuryDao);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            EXTERNAL
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /**
     *  @notice - Fetch the price of the token in $ under 18 decimals
     *            OR
     *          - Revert if several conditions are not respected
     *  @param erc20Address address of the token we want to fetch the price
     *  @return price used for the execution of the order
     */
    function getAndVerifyOracle(address erc20Address) external view returns (uint256) {
        return _getAndVerificationOracle(oracleParametersPerERC20[erc20Address]);
    }

    /**
     *  @notice - Fetch the CVG price in $ under 18 decimals
     *            OR
     *          - Revert if 1 of the conditions is not verified
     * */
    function getAndVerifyCvgPrice() external view returns (uint256) {
        return _getAndVerificationOracle(oracleParametersPerERC20[cvg]);
    }

    /**
     *  @notice  Fetch the price and all the parameters checked in the Oracle
     *  @param erc20Address address  token we want to fetch the price of
     *  @return executionPrice uint256 execution price 
     *  @return limitPrice uint256 price to compare with the execution price for low & high limits
     *  @return isNotTooLow bool low limit checking between the execution & limit price
     *  @return isNotTooHigh bool high limit checking between the execution & limit price
     *  @return isEthVerifed bool eth price computation is verified
     *  @return isNotStale bool limit price is stale or not

     */
    function getDataForVerification(
        address erc20Address
    )
        external
        view
        returns (
            uint256 executionPrice,
            uint256 limitPrice,
            bool isNotTooLow,
            bool isNotTooHigh,
            bool isEthVerifed,
            bool isNotStale,
            bool areStableVerified,
            bool areLimitsVerified
        )
    {
        IOracleStruct.OracleParams memory oracleParams = oracleParametersPerERC20[erc20Address];
        (executionPrice, limitPrice, isNotTooLow, isNotTooHigh, isEthVerifed, isNotStale) = _getDataForVerification(
            oracleParams
        );
        areStableVerified = _verifyStableInPath(oracleParams.stablesToCheck);

        areLimitsVerified = limitPrice > oracleParams.minPrice && limitPrice > oracleParams.maxPrice;
    }

    /**
     *  @notice - Fetch the price of 2 tokens in $ under 18 decimals
     *            OR
     *          - Revert if 1 of the conditions is not verified
     *  @param token0 address of the token we want to fetch the price of
     *  @param token1 address of the token we want to fetch the price of
     *  @return price of token 0 used for the execution of the order
     *  @return price of token 1 used for the execution of the order
     */
    function getAndVerifyTwoPrices(address token0, address token1) external view returns (uint256, uint256) {
        return (
            _getAndVerificationOracle(oracleParametersPerERC20[token0]),
            _getAndVerificationOracle(oracleParametersPerERC20[token1])
        );
    }

    /// @notice Compute the ETH price based on the associated LP
    function getEthPriceOracleUnverified() external view returns (uint256 price) {
        (, uint256 priceUsd, ) = _getPriceOracle(oracleParametersPerERC20[WETH]);
        return priceUsd;
    }

    /// @notice Compute the CVG price based on the associated LP
    function getCvgPriceOracleUnverified() external view returns (uint256 price) {
        (, uint256 priceUsd, ) = _getPriceOracle(oracleParametersPerERC20[cvg]);
        return priceUsd;
    }

    /// @notice Compute the CVG price based on the associated LP
    function getPriceOracleUnverified(address erc20) external view returns (uint256 price) {
        (, uint256 priceUsd, ) = _getPriceOracle(oracleParametersPerERC20[erc20]);
        return priceUsd;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            ONLYOWNER
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /**
     *  @notice Set the Oracle params of a token
     *  @param erc20Address address of the token we want to fetch the price of
     *  @param tokenOracleParams oracleParams used for the token computation in dollar
     */
    function setTokenOracleParams(
        address erc20Address,
        IOracleStruct.OracleParams calldata tokenOracleParams
    ) external onlyOwner {
        oracleParametersPerERC20[erc20Address] = tokenOracleParams;
    }

    /**
     *  @notice Set CVG token address
     *  @param _cvg address of the cvg token
     */
    function setCvgToken(address _cvg) external onlyOwner {
        cvg = _cvg;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        INTERNAL
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    function _getDataForVerification(
        IOracleStruct.OracleParams memory oracleParams
    ) internal view returns (uint256, uint256, bool, bool, bool, bool) {
        if (uint256(oracleParams.poolType) < 3) {
            return _getDataForVerifyChainlink(oracleParams);
        }
        return _getDataForVerifyCurve(oracleParams);
    }

    function _verifyStableInPath(address[] memory stables) internal view returns (bool) {
        bool isStablesVerified = true;
        for (uint i = 0; i < stables.length; ) {
            IOracleStruct.OracleParams memory oracleParams = oracleParametersPerERC20[stables[i]];
            (uint256 price, uint256 lastUpdateDate) = _getAggregatorPrice(oracleParams.aggregatorOracle);
            uint256 delta = (ONE_ETH * oracleParams.deltaLimitOracle) / 10_000;
            isStablesVerified =
                ONE_ETH + delta > price &&
                ONE_ETH - delta < price &&
                lastUpdateDate + oracleParams.maxLastUpdate > block.timestamp;

            unchecked {
                ++i;
            }
        }
        return isStablesVerified;
    }

    /**
     *  @notice
     *  @param oracleParams used for the price computation
     */
    function _getDataForVerifyChainlink(
        IOracleStruct.OracleParams memory oracleParams
    ) internal view returns (uint256, uint256, bool, bool, bool, bool) {
        /// @dev Fetch price through CvgOracle
        (, uint256 poolPriceUsd, bool isEthVerified) = _getPriceOracle(oracleParams);

        uint256 delta = (oracleParams.deltaLimitOracle * poolPriceUsd) / 10_000;

        (uint256 limitPrice, uint256 lastUpdateDate) = _getAggregatorPrice(oracleParams.aggregatorOracle);
        bool isNotStale = lastUpdateDate + oracleParams.maxLastUpdate > block.timestamp;

        return (
            poolPriceUsd,
            limitPrice,
            poolPriceUsd + delta > limitPrice,
            poolPriceUsd - delta < limitPrice,
            isEthVerified,
            isNotStale
        );
    }

    function _getDataForVerifyCurve(
        IOracleStruct.OracleParams memory oracleParams
    ) internal view returns (uint256, uint256, bool, bool, bool, bool) {
        /// @dev Get price
        (uint256 poolOraclePriceNotTransformed, uint256 poolPriceUsd, bool isEthVerified) = _getPriceOracle(
            oracleParams
        );
        bool isNotStale = ICrvPool(oracleParams.poolAddress).last_prices_timestamp() + oracleParams.maxLastUpdate >
            block.timestamp;

        uint256 lastPrice = _getCurveLastPrice(
            oracleParams.poolAddress,
            oracleParams.poolType,
            oracleParams.isReversed,
            oracleParams.twapOrK
        );

        uint256 delta = (oracleParams.deltaLimitOracle * poolOraclePriceNotTransformed) / 10_000;

        return (
            poolPriceUsd,
            lastPrice,
            poolOraclePriceNotTransformed + delta > lastPrice,
            poolOraclePriceNotTransformed - delta < lastPrice,
            isEthVerified,
            isNotStale
        );
    }

    function _getAndVerificationOracle(IOracleStruct.OracleParams memory oracleParams) internal view returns (uint256) {
        (
            uint256 poolOraclePrice,
            uint256 limitPrice,
            bool isNotTooLow,
            bool isNoTooHigh,
            bool isEthVerified,
            bool isNotStale
        ) = _getDataForVerification(oracleParams);

        require(isNotTooLow, "LIMIT_TOO_LOW");
        require(isNoTooHigh, "LIMIT_TOO_HIGH");
        require(isEthVerified, "ETH_NOT_VERIFIED");
        require(isNotStale, "STALE_PRICE");
        require(_verifyStableInPath(oracleParams.stablesToCheck), "STABLES_NOT_VERIFIED");
        require(limitPrice > oracleParams.minPrice && limitPrice < oracleParams.maxPrice, "PRICE_OUT_OF_LIMITS");
        return poolOraclePrice;
    }

    /**
     *  @notice Compute the price of a UNISWAP or Curve pool regarding the poolType
     *  @param oracleParams oracleParams IOracleStruct.OracleParams
     */
    function _getPriceOracle(
        IOracleStruct.OracleParams memory oracleParams
    ) internal view returns (uint256, uint256, bool) {
        IOracleStruct.PoolType poolType = oracleParams.poolType;
        require(uint256(oracleParams.poolType) < 5, "WRONG_TYPE");
        uint256 priceNotTransformed;
        uint256 priceUsd;
        bool isEthVerified;
        if (poolType == IOracleStruct.PoolType.STABLE) {
            priceNotTransformed = ONE_ETH;
        } else if (poolType == IOracleStruct.PoolType.UNI_V2) {
            priceNotTransformed = _getV2Price(oracleParams.poolAddress);
        } else if (poolType == IOracleStruct.PoolType.UNI_V3) {
            priceNotTransformed = _getV3Price(oracleParams.poolAddress, oracleParams.twapOrK);
        } else if (poolType == IOracleStruct.PoolType.CURVE_DUO) {
            priceNotTransformed = ICrvPool(oracleParams.poolAddress).price_oracle();
        } else {
            priceNotTransformed = ITriCrvPool(oracleParams.poolAddress).price_oracle(oracleParams.twapOrK);
        }

        priceNotTransformed = _treatmentReversed(priceNotTransformed, oracleParams.isReversed);
        (priceUsd, isEthVerified) = _treatmentEth(priceNotTransformed, oracleParams.isEthPriceRelated);

        return (priceNotTransformed, priceUsd, isEthVerified);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                    PRICE COMPUTATION
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /**
     *  @notice Compute the actual price of an UNIV2 LP, this price fetching is always combined with a Chainlink Aggregator
     *  @param uniswapV2PoolAddress Address of the Uniswap V2 Pool
     */
    function _getV2Price(address uniswapV2PoolAddress) internal view returns (uint256) {
        IUniswapV2Pair uniswapPool = IUniswapV2Pair(uniswapV2PoolAddress);
        (uint112 reserve0, uint112 reserve1, ) = uniswapPool.getReserves();

        return
            (reserve0 * 10 ** (36 - IERC20Metadata(uniswapPool.token0()).decimals())) /
            (reserve1 * 10 ** (18 - IERC20Metadata(uniswapPool.token1()).decimals()));
    }

    /**
     *  @notice Compute the Time Weighted Average Price IN WEI
     *  @param uniswapV3PoolAddress address
     *  @param twapOrK uint32
     */
    function _getV3Price(address uniswapV3PoolAddress, uint32 twapOrK) internal view returns (uint256) {
        uint256 price;
        IUniswapV3Pool uniswapV3Pool = IUniswapV3Pool(uniswapV3PoolAddress);
        if (twapOrK == 0) {
            // return the current price if twapOrK == 0
            (price, , , , , , ) = uniswapV3Pool.slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapOrK; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = uniswapV3Pool.observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            price = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(twapOrK)))
            );
        }
        uint256 token0Decimals = IERC20Metadata(uniswapV3Pool.token0()).decimals();
        uint256 token1Decimals = IERC20Metadata(uniswapV3Pool.token1()).decimals();

        price =
            (((price * price) / FixedPoint96.Q96) *
                10 **
                    (
                        token0Decimals <= token1Decimals
                            ? 18 - (token1Decimals - token0Decimals)
                            : 18 + (token0Decimals - token1Decimals)
                    )) /
            FixedPoint96.Q96;

        return price;
    }

    function _treatmentReversed(uint256 price, bool isReversed) internal pure returns (uint256) {
        return isReversed ? TEN_36 / price : price;
    }

    /**
     *  @notice Post Treatment of a given price pool to align all prices on 18 decimals
     *  @param price of the pool
     *  @param isEthPriceRelated bool
     */
    function _treatmentEth(uint256 price, bool isEthPriceRelated) internal view returns (uint256, bool) {
        bool isEthVerified = true;

        if (isEthPriceRelated) {
            (
                uint256 ethPrice,
                ,
                bool isOracleNotTooLow,
                bool isOracleNotTooHigh,
                ,
                bool isNotStale
            ) = _getDataForVerification(oracleParametersPerERC20[WETH]);

            isEthVerified = isOracleNotTooLow && isOracleNotTooHigh && isNotStale;
            price = (price * ethPrice) / ONE_ETH;
        }

        return (price, isEthVerified);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                    FETCH LIMITS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /**
     *  @notice Get the token price from the Chainlink aggregator
     *  @return aggregator AggregatorV3Interface
     */
    function _getAggregatorPrice(AggregatorV3Interface aggregator) internal view returns (uint256, uint256) {
        (, int256 chainlinkPrice, , uint256 lastUpdate, ) = aggregator.latestRoundData();
        return (uint256(chainlinkPrice) * 10 ** (18 - aggregator.decimals()), lastUpdate);
    }

    function _getCurveLastPrice(
        address curvePool,
        IOracleStruct.PoolType poolType,
        bool isReversed,
        uint256 k
    ) internal view returns (uint256) {
        uint256 lastPrice;
        if (poolType == IOracleStruct.PoolType.CURVE_DUO) {
            lastPrice = ICrvPool(curvePool).last_prices();
        } else {
            lastPrice = ITriCrvPool(curvePool).last_prices(k);
        }

        lastPrice = _treatmentReversed(lastPrice, isReversed);
        return lastPrice;
    }
}
