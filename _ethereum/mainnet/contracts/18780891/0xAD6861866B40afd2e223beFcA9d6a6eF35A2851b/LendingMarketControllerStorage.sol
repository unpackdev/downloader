// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./EnumerableSet.sol";

struct ObservationPeriodLog {
    uint256 totalAmount;
    uint256 totalFutureValue;
}

struct TerminationCurrencyCache {
    int256 price;
    uint8 decimals;
}

library LendingMarketControllerStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256("sf.storage.lendingMarketController")) - 1);

    struct Storage {
        uint256 marketBasePeriod;
        uint256 terminationDate;
        mapping(bytes32 ccy => TerminationCurrencyCache currency) terminationCurrencyCaches;
        mapping(bytes32 ccy => uint256 ratio) terminationCollateralRatios;
        mapping(bytes32 ccy => uint8[] orderBookIds) orderBookIdLists;
        mapping(bytes32 ccy => address lendingMarket) lendingMarkets;
        mapping(bytes32 ccy => address futureValueVault) futureValueVaults;
        mapping(bytes32 ccy => uint256 unitPrice) minDebtUnitPrices;
        mapping(bytes32 ccy => uint256 genesisDate) genesisDates;
        mapping(bytes32 ccy => mapping(uint256 maturity => uint256 amount)) pendingOrderAmounts;
        // Order book id history to get order book id from maturity
        mapping(bytes32 ccy => mapping(uint256 maturity => uint8 orderBookIds)) maturityOrderBookIds;
        // List of maturity that the user has open orders or positions
        mapping(bytes32 ccy => mapping(address user => EnumerableSet.UintSet maturities)) usedMaturities;
        // Observation period logs that is used for auto-rolls
        mapping(bytes32 ccy => mapping(uint256 maturity => ObservationPeriodLog log)) observationPeriodLogs;
        // List of currency that the user has open orders or positions
        mapping(address user => EnumerableSet.Bytes32Set currency) usedCurrencies;
        mapping(address user => bool isRedeemed) isRedeemed;
    }

    function slot() internal pure returns (Storage storage r) {
        bytes32 _slot = STORAGE_SLOT;
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := _slot
        }
    }
}
