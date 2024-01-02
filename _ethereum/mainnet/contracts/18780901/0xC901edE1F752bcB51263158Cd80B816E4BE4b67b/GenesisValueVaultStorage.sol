// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

struct MaturityUnitPrice {
    uint256 unitPrice;
    uint256 compoundFactor;
    uint256 next;
    uint256 prev;
}

struct AutoRollLog {
    uint256 unitPrice;
    uint256 lendingCompoundFactor;
    uint256 borrowingCompoundFactor;
    uint256 next;
    uint256 prev;
}

library GenesisValueVaultStorage {
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256("sf.storage.genesisValueVault")) - 1);

    struct Storage {
        mapping(bytes32 ccy => bool isInitialized) isInitialized;
        mapping(bytes32 ccy => uint256 compoundFactor) initialCompoundFactors;
        mapping(bytes32 ccy => uint256 compoundFactor) lendingCompoundFactors;
        mapping(bytes32 ccy => uint256 compoundFactor) borrowingCompoundFactors;
        mapping(bytes32 ccy => uint256 maturity) currentMaturity;
        mapping(bytes32 ccy => uint8 decimals) decimals;
        mapping(bytes32 ccy => mapping(address user => int256 balance)) balances;
        mapping(bytes32 ccy => uint256 amount) totalLendingSupplies;
        mapping(bytes32 ccy => uint256 amount) totalBorrowingSupplies;
        // Total amount supplied per maturity
        mapping(bytes32 ccy => mapping(uint256 maturity => int256 balance)) maturityBalances;
        mapping(bytes32 ccy => mapping(uint256 maturity => AutoRollLog log)) autoRollLogs;
        // Maturity when the user receives the balance on the target currency
        mapping(bytes32 ccy => mapping(address user => uint256 maturity)) userMaturities;
    }

    function slot() internal pure returns (Storage storage r) {
        bytes32 _slot = STORAGE_SLOT;
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := _slot
        }
    }
}
