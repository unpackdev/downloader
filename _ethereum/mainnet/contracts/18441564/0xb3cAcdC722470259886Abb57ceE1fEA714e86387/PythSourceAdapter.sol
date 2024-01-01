// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./IPyth.sol";
import "./SnapshotSource.sol";
import "./DecimalLib.sol";

/**
 * @title PythSourceAdapter contract to read data from Pyth and standardize it for the OEV.
 */

abstract contract PythSourceAdapter is SnapshotSource {
    IPyth public immutable PYTH_SOURCE;
    bytes32 public immutable PYTH_PRICE_ID;

    event SourceSet(address indexed sourceOracle, bytes32 indexed pythPriceId);

    constructor(IPyth _pyth, bytes32 _pythPriceId) {
        PYTH_SOURCE = _pyth;
        PYTH_PRICE_ID = _pythPriceId;

        emit SourceSet(address(_pyth), _pythPriceId);
    }

    /**
     * @notice Returns the latest data from the source.
     * @return answer The latest answer in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function getLatestSourceData() public view virtual override returns (int256, uint256) {
        IPyth.Price memory pythPrice = PYTH_SOURCE.getPriceUnsafe(PYTH_PRICE_ID);
        return (_convertDecimalsWithExponent(pythPrice.price, pythPrice.expo), pythPrice.publishTime);
    }

    /**
     * @notice Tries getting latest data as of requested timestamp. If this is not possible, returns the earliest data
     * available past the requested timestamp within provided traversal limitations.
     * @dev Pyth does not support historical lookups so this uses SnapshotSource to get historic data.
     * @param timestamp The timestamp to try getting latest data at.
     * @param maxTraversal The maximum number of rounds to traverse when looking for historical data.
     * @return answer The answer as of requested timestamp, or earliest available data if not available, in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function tryLatestDataAt(uint256 timestamp, uint256 maxTraversal)
        public
        view
        virtual
        override
        returns (int256, uint256)
    {
        Snapshot memory snapshot = _tryLatestDataAt(timestamp, maxTraversal);
        return (snapshot.answer, snapshot.timestamp);
    }

    // Handle a per-price "expo" (decimal) value from pyth.
    function _convertDecimalsWithExponent(int256 answer, int32 expo) internal pure returns (int256) {
        // Expo is pyth's way of expressing decimals. -18 is equivalent to 18 decimals. -5 is equivalent to 5.
        if (expo <= 0) return DecimalLib.convertDecimals(answer, uint8(uint32(-expo)), 18);
        // Add the _decimals and expo in the case that expo is positive since it means that the fixed point number is
        // _smaller_ than the true value. This case may never be hit, it seems preferable to reverting.
        else return DecimalLib.convertDecimals(answer, 0, 18 + uint8(uint32(expo)));
    }
}
