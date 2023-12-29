// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IOracleWrapper.sol";
import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./FullMath.sol";
import "./SafeCast.sol";

/// @title ChainLink Oracle wrapper
contract ChainLinkOracle is IOracleWrapper, Ownable {
    // #region constant variable.

    // solhint-disable-next-line private-vars-leading-underscore
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    // #endregion constant variable.

    // #region immutable variable.

    uint8 public immutable token0Decimals;
    uint8 public immutable token1Decimals;
    AggregatorV3Interface public immutable priceFeed;
    AggregatorV3Interface public immutable sequencerUptimeFeed;
    bool internal immutable _isPriceFeedInversed;

    // #endregion immutable variable.

    uint256 public outdated;

    // #region events.

    event LogSetOutdated(
        address oracle,
        uint256 oldOutdated,
        uint256 newOutdated
    );

    // #endregion events.

    constructor(
        uint8 token0Decimals_,
        uint8 token1Decimals_,
        address priceFeed_,
        address sequencerUptimeFeed_,
        uint256 outdated_,
        bool isPriceFeedInversed_
    ) {
        require(priceFeed_ != address(0), "ZA");
        token0Decimals = token0Decimals_;
        token1Decimals = token1Decimals_;
        priceFeed = AggregatorV3Interface(priceFeed_);
        sequencerUptimeFeed = AggregatorV3Interface(sequencerUptimeFeed_);
        outdated = outdated_;
        _isPriceFeedInversed = isPriceFeedInversed_;
    }

    /// @notice set outdated value
    /// @param outdated_ new outdated value
    function setOutdated(uint256 outdated_) external onlyOwner {
        uint256 oldOutdated = outdated;
        outdated = outdated_;
        emit LogSetOutdated(address(this), oldOutdated, outdated_);
    }

    /// @notice get Price of token 1 over token 0
    /// @return price0
    function getPrice0() external view override returns (uint256 price0) {
        if (address(sequencerUptimeFeed) != address(0)) _checkSequencer();

        try priceFeed.latestRoundData() returns (
            uint80,
            int256 price,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            require(
                block.timestamp - updatedAt <= outdated, // solhint-disable-line not-rely-on-time
                "ChainLinkOracle: outdated."
            );

            uint8 priceFeedDecimals = priceFeed.decimals();
            if (_isPriceFeedInversed) {
                return
                    FullMath.mulDiv(
                        FullMath.mulDiv(
                            10 ** (2 * priceFeedDecimals),
                            10 ** token1Decimals,
                            SafeCast.toUint256(price)
                        ),
                        1,
                        10 ** priceFeedDecimals
                    );
            }
            return
                FullMath.mulDiv(
                    SafeCast.toUint256(price),
                    10 ** token1Decimals,
                    10 ** priceFeedDecimals
                );
        } catch {
            revert("ChainLinkOracle: price feed call failed.");
        }
    }

    /// @notice get Price of token 0 over token 1
    /// @return price1
    function getPrice1() external view override returns (uint256 price1) {
        if (address(sequencerUptimeFeed) != address(0)) _checkSequencer();

        try priceFeed.latestRoundData() returns (
            uint80,
            int256 price,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            require(
                block.timestamp - updatedAt <= outdated, // solhint-disable-line not-rely-on-time
                "ChainLinkOracle: outdated."
            );

            uint8 priceFeedDecimals = priceFeed.decimals();
            if (!_isPriceFeedInversed) {
                return
                    FullMath.mulDiv(
                        FullMath.mulDiv(
                            10 ** (2 * priceFeedDecimals),
                            10 ** token0Decimals,
                            SafeCast.toUint256(price)
                        ),
                        1,
                        10 ** priceFeedDecimals
                    );
            }
            return
                FullMath.mulDiv(
                    SafeCast.toUint256(price),
                    10 ** token0Decimals,
                    10 ** priceFeedDecimals
                );
        } catch {
            revert("ChainLinkOracle: price feed call failed.");
        }
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
}
