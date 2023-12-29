// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./AggregatorV3Interface.sol";
import "./IWstETH.sol";
import "./FullMath.sol";
import "./SafeCast.sol";

// #region errors.

error AddressZero();
error GetStETHByWstETHCallFailed();
error GetWstETHByStETHCallFailed();

// #endregion errors.

contract WrappedFeed {
    AggregatorV3Interface public immutable priceFeed;
    IWstETH public immutable wstETH;
    bool public immutable ispriceFeedInversed;

    constructor(
        AggregatorV3Interface priceFeed_,
        IWstETH wstETH_,
        bool ispriceFeedInversed_
    ) {
        if (address(priceFeed_) == address(0) || address(wstETH_) == address(0))
            revert AddressZero();
        priceFeed = priceFeed_;
        wstETH = wstETH_;
        ispriceFeedInversed = ispriceFeedInversed_;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = priceFeed
            .latestRoundData();
        uint256 denominator = 1e18;
        uint256 price = SafeCast.toUint256(answer);
        if (ispriceFeedInversed) {
            try wstETH.getWstETHByStETH(denominator) returns (
                uint256 wstETHAmounts
            ) {
                price = FullMath.mulDiv(price, wstETHAmounts, denominator);
            } catch {
                revert GetWstETHByStETHCallFailed();
            }
        } else {
            try wstETH.getStETHByWstETH(denominator) returns (
                uint256 stETHAmounts
            ) {
                price = FullMath.mulDiv(price, stETHAmounts, denominator);
            } catch {
                revert GetStETHByWstETHCallFailed();
            }
        }
        answer = SafeCast.toInt256(price);
    }

    function decimals() external view returns (uint8) {
        return priceFeed.decimals();
    }
}
