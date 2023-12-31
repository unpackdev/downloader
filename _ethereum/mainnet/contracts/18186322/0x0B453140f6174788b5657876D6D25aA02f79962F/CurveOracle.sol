// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC20Metadata.sol";
import "./SafeCast.sol";
import "./IAeraV2Oracle.sol";
import "./ICurveFiPool.sol";
import "./Constants.sol";

/// @title CurveOracle
/// @notice Used to calculate price of tokens in a Curve V2 pool.
contract CurveOracle is IAeraV2Oracle {
    /// @notice The address of underlying Curve pool.
    ICurveFiPool public immutable pool;

    /// @notice Decimals of price returned by this oracle.
    uint8 public constant decimals = 18;

    /// ERRORS ///

    error AeraPeriphery__CurvePoolIsZeroAddress();
    error AeraPeriphery__InvalidCurvePool();

    /// FUNCTIONS ///

    /// @notice Initialize the oracle contract.
    /// @param pool_ The address of the underlying Curve pool.
    constructor(address pool_) {
        // Requirements: check Curve pool integrity.
        if (pool_ == address(0)) {
            revert AeraPeriphery__CurvePoolIsZeroAddress();
        }
        if (pool_.code.length == 0) {
            revert AeraPeriphery__InvalidCurvePool();
        }

        ICurveFiPool c = ICurveFiPool(pool_);

        // Requirements: check that price_oracle works.
        try c.price_oracle() returns (uint256) {}
        catch {
            revert AeraPeriphery__InvalidCurvePool();
        }

        // Effects: set pool and oracle decimals.
        pool = c;
    }

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
        uint256 price = pool.price_oracle();

        roundId = 0;
        answer = SafeCast.toInt256(price);
        startedAt = 0;
        // Price is always interpolated against latest block timestamp.
        // However, last_prices_timestamp registers the latest pool action.
        updatedAt = pool.last_prices_timestamp();
        answeredInRound = 0;
    }
}
