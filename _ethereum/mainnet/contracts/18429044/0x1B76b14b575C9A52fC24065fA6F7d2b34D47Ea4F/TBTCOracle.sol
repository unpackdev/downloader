// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Math.sol";
import "./SafeCast.sol";
import "./IAeraV2Oracle.sol";
import "./ICurveFiStableSwapPool.sol";

/// @title TBTCOracle
/// @notice Calculates price of tBTC tokens by converting tBTC -> WBTC -> BTC -> ETH.
/// @dev This oracle is intended for mainnet deployment only due to hardcoded addresses.
contract TBTCOracle is IAeraV2Oracle {
    /// @notice Address of the tBTC/WBTC Curve pool.
    ICurveFiStableSwapPool public immutable tbtcWbtcPool =
        ICurveFiStableSwapPool(0xB7ECB2AA52AA64a717180E030241bC75Cd946726);
    IAeraV2Oracle public immutable wbtcBtcOracle =
        IAeraV2Oracle(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    IAeraV2Oracle public immutable btcEthOracle =
        IAeraV2Oracle(0xdeb288F737066589598e9214E782fa5A8eD689e8);

    // @notice Final scalar used to divide price in 18 decimals.
    //    wbtcBtcOracle decimals is 8, btcEthOracle decimals is 18
    int256 public constant FINAL_SCALAR = 10 ** (18 + 8);

    /// @notice Decimals of price returned by this oracle.
    uint8 public constant decimals = 18; // solhint-disable-line const-name-snakecase

    /// FUNCTIONS ///
    /// @inheritdoc IAeraV2Oracle
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
        uint256 wbtcPrice = tbtcWbtcPool.price_oracle();
        uint256 poolUpdatedAt = tbtcWbtcPool.ma_last_time();

        (, int256 wBtcBtcAnswer,, uint256 wBtcBtcUpdatedAt,) =
            wbtcBtcOracle.latestRoundData();

        (, int256 btcEthAnswer,, uint256 btcEthUpdatedAt,) =
            btcEthOracle.latestRoundData();

        answer = SafeCast.toInt256(wbtcPrice) * wBtcBtcAnswer * btcEthAnswer
            / FINAL_SCALAR;
        roundId = 0;
        startedAt = 0;
        updatedAt = Math.min(
            poolUpdatedAt, Math.min(wBtcBtcUpdatedAt, btcEthUpdatedAt)
        );
        answeredInRound = 0;
    }
}
