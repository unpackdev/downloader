// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IOracleWrapper.sol";
import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./FullMath.sol";
import "./SafeCast.sol";

/// @title ChainLink Oracle wrapper
contract ChainLinkOraclePivot is IOracleWrapper, Ownable {
    // #region constant variable.

    // solhint-disable-next-line private-vars-leading-underscore
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    // #endregion constant variable.

    // #region immutable variable.

    uint8 public immutable token0Decimals;
    uint8 public immutable token1Decimals;
    AggregatorV3Interface public immutable priceFeedA;
    AggregatorV3Interface public immutable priceFeedB;
    AggregatorV3Interface public immutable sequencerUptimeFeed;
    bool internal immutable _ispriceFeedAInversed;
    bool internal immutable _ispriceFeedBInversed;

    // #endregion immutable variable.

    uint256 public outdatedA;
    uint256 public outdatedB;

    // #region events.

    event LogSetOutdatedA(
        address oracle,
        uint256 oldOutdated,
        uint256 newOutdated
    );

    event LogSetOutdatedB(
        address oracle,
        uint256 oldOutdated,
        uint256 newOutdated
    );

    // #endregion events.

    constructor(
        uint8 token0Decimals_,
        uint8 token1Decimals_,
        address priceFeedA_,
        address priceFeedB_,
        address sequencerUptimeFeed_,
        uint256 outdatedA_,
        uint256 outdatedB_,
        bool ispriceFeedAInversed_,
        bool ispriceFeedBInversed_
    ) {
        require(priceFeedA_ != address(0) || priceFeedB_ != address(0), "ZA");
        token0Decimals = token0Decimals_;
        token1Decimals = token1Decimals_;
        priceFeedA = AggregatorV3Interface(priceFeedA_);
        priceFeedB = AggregatorV3Interface(priceFeedB_);
        sequencerUptimeFeed = AggregatorV3Interface(sequencerUptimeFeed_);
        outdatedA = outdatedA_;
        outdatedB = outdatedB_;
        _ispriceFeedAInversed = ispriceFeedAInversed_;
        _ispriceFeedBInversed = ispriceFeedBInversed_;
    }

    /// @notice set outdated value for Token A
    /// @param outdatedA_ new outdated value
    function setOutdatedA(uint256 outdatedA_) external onlyOwner {
        uint256 oldOutdatedA = outdatedA;
        outdatedA = outdatedA_;
        emit LogSetOutdatedA(address(this), oldOutdatedA, outdatedA_);
    }

    /// @notice set outdated value for Token B
    /// @param outdatedB_ new outdated value
    function setOutdatedB(uint256 outdatedB_) external onlyOwner {
        uint256 oldOutdatedB = outdatedB;
        outdatedB = outdatedB_;
        emit LogSetOutdatedB(address(this), oldOutdatedB, outdatedB_);
    }

    /// @notice get Price of token 1 over token 0
    /// @return price0
    // solhint-disable-next-line function-max-lines, code-complexity
    function getPrice0() external view override returns (uint256 price0) {
        if (address(sequencerUptimeFeed) != address(0)) _checkSequencer();

        (
            uint256 priceA,
            uint256 priceB,
            uint8 priceFeedADecimals,
            uint8 priceFeedBDecimals
        ) = _getLatestRoundData();

        // #region 1st case.

        if (!_ispriceFeedAInversed && !_ispriceFeedBInversed) {
            return
                FullMath.mulDiv(
                    priceA * priceB,
                    10 ** token1Decimals,
                    10 ** (priceFeedADecimals + priceFeedBDecimals)
                );
        }

        // #endregion 1st case.

        // #region 2nd case.

        if (_ispriceFeedAInversed && !_ispriceFeedBInversed) {
            return
                FullMath.mulDiv(
                    FullMath.mulDiv(
                        (10 ** (2 * priceFeedADecimals)) * priceB,
                        10 ** token1Decimals,
                        priceA
                    ),
                    1,
                    10 ** (priceFeedADecimals + priceFeedBDecimals)
                );
        }

        // #endregion 2nd case.

        // #region 3rd case.

        if (!_ispriceFeedAInversed && _ispriceFeedBInversed) {
            return
                FullMath.mulDiv(
                    FullMath.mulDiv(
                        (10 ** (2 * priceFeedBDecimals)) * priceA,
                        10 ** token1Decimals,
                        priceB
                    ),
                    1,
                    10 ** (priceFeedADecimals + priceFeedBDecimals)
                );
        }

        // #endregion 3rd case.

        // #region 4th case.

        if (_ispriceFeedAInversed && _ispriceFeedBInversed) {
            return
                FullMath.mulDiv(
                    FullMath.mulDiv(
                        10 ** (2 * (priceFeedADecimals + priceFeedBDecimals)),
                        10 ** token1Decimals,
                        priceA * priceB
                    ),
                    1,
                    10 ** (priceFeedADecimals + priceFeedBDecimals)
                );
        }

        // #endregion 4th case.
    }

    /// @notice get Price of token 0 over token 1
    /// @return price1
    // solhint-disable-next-line function-max-lines, code-complexity
    function getPrice1() external view override returns (uint256 price1) {
        if (address(sequencerUptimeFeed) != address(0)) _checkSequencer();

        (
            uint256 priceA,
            uint256 priceB,
            uint8 priceFeedADecimals,
            uint8 priceFeedBDecimals
        ) = _getLatestRoundData();

        // #region 1st case.

        if (!_ispriceFeedAInversed && !_ispriceFeedBInversed) {
            return
                FullMath.mulDiv(
                    FullMath.mulDiv(
                        10 ** (2 * (priceFeedADecimals + priceFeedBDecimals)),
                        10 ** token0Decimals,
                        priceA * priceB
                    ),
                    1,
                    10 ** (priceFeedADecimals + priceFeedBDecimals)
                );
        }

        // #endregion 1st case.

        // #region 2nd case.

        if (_ispriceFeedAInversed && !_ispriceFeedBInversed) {
            return
                FullMath.mulDiv(
                    FullMath.mulDiv(
                        (10 ** (2 * priceFeedBDecimals)) * priceA,
                        10 ** token0Decimals,
                        priceB
                    ),
                    1,
                    10 ** (priceFeedADecimals + priceFeedBDecimals)
                );
        }

        // #endregion 2nd case.

        // #region 3rd case.

        if (!_ispriceFeedAInversed && _ispriceFeedBInversed) {
            return
                FullMath.mulDiv(
                    FullMath.mulDiv(
                        (10 ** (2 * priceFeedADecimals)) * priceB,
                        10 ** token0Decimals,
                        priceA
                    ),
                    1,
                    10 ** (priceFeedADecimals + priceFeedBDecimals)
                );
        }

        // #endregion 3rd case.

        // #region 4th case.

        if (_ispriceFeedAInversed && _ispriceFeedBInversed) {
            return
                FullMath.mulDiv(
                    priceA * priceB,
                    10 ** token0Decimals,
                    10 ** (priceFeedADecimals + priceFeedBDecimals)
                );
        }

        // #endregion 4th case.
    }

    // solhint-disable-next-line function-max-lines
    function _getLatestRoundData()
        internal
        view
        returns (
            uint256 priceA,
            uint256 priceB,
            uint8 priceFeedADecimals,
            uint8 priceFeedBDecimals
        )
    {
        try priceFeedA.latestRoundData() returns (
            uint80,
            int256 price,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            require(
                block.timestamp - updatedAt <= outdatedA, // solhint-disable-line not-rely-on-time
                "ChainLinkOracle: priceFeedA outdated."
            );

            priceA = SafeCast.toUint256(price);
        } catch {
            revert("ChainLinkOracle: price feed A call failed.");
        }

        try priceFeedB.latestRoundData() returns (
            uint80,
            int256 price,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            require(
                block.timestamp - updatedAt <= outdatedB, // solhint-disable-line not-rely-on-time
                "ChainLinkOracle: priceFeedB outdated."
            );

            priceB = SafeCast.toUint256(price);
        } catch {
            revert("ChainLinkOracle: price feed B call failed.");
        }

        priceFeedADecimals = priceFeedA.decimals();
        priceFeedBDecimals = priceFeedB.decimals();
    }

    /// @dev only needed for optimistic L2 chain
    function _checkSequencer() internal view {
        (, int256 answer, uint256 startedAt, , ) = sequencerUptimeFeed
            .latestRoundData();

        require(answer == 0, "ChainLinkOracle: sequencer down");

        // Make sure the grace period has passed after the
        // sequencer is back up.
        require(
            block.timestamp - startedAt > GRACE_PERIOD_TIME, // solhint-disable-line not-rely-on-time, max-line-length
            "ChainLinkOracle: grace period not over"
        );
    }

    function _getPrice(
        bool isPriceFeedInversed_,
        uint8 priceFeedDecimals_,
        uint8 tokenDecimals_,
        int256 price_
    ) internal pure returns (uint256) {
        if (!isPriceFeedInversed_) {
            return
                FullMath.mulDiv(
                    FullMath.mulDiv(
                        10 ** (2 * priceFeedDecimals_),
                        10 ** tokenDecimals_,
                        SafeCast.toUint256(price_)
                    ),
                    1,
                    10 ** priceFeedDecimals_
                );
        }
        return
            FullMath.mulDiv(
                SafeCast.toUint256(price_),
                10 ** tokenDecimals_,
                10 ** priceFeedDecimals_
            );
    }
}
