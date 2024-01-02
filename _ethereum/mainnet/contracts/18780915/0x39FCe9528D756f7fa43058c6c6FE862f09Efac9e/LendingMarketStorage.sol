// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./ProtocolTypes.sol";
import "./OrderBookLib.sol";

struct ItayoseLog {
    uint256 openingUnitPrice;
    uint256 lastLendUnitPrice;
    uint256 lastBorrowUnitPrice;
}

library LendingMarketStorage {
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256("sf.storage.lendingMarket")) - 1);

    struct Storage {
        bytes32 ccy;
        uint8 lastOrderBookId;
        // Order fee rate received by protocol (in basis point)
        uint256 orderFeeRate;
        // Rate limit range of yield for the circuit breaker
        uint256 circuitBreakerLimitRange;
        mapping(uint8 orderBookId => OrderBookLib.OrderBook orderBook) orderBooks;
        mapping(uint256 maturity => bool isReady) isReady;
        mapping(uint256 maturity => ItayoseLog log) itayoseLogs;
    }

    function slot() internal pure returns (Storage storage r) {
        bytes32 _slot = STORAGE_SLOT;
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := _slot
        }
    }
}
