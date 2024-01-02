// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./EnumerableSet.sol";

library TokenVaultStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256("sf.storage.tokenVault")) - 1);

    struct Storage {
        // Liquidation threshold rate (in basis point)
        uint256 liquidationThresholdRate;
        // Liquidation fee rate received by protocol (in basis point)
        uint256 liquidationProtocolFeeRate;
        // Liquidation fee rate received by liquidators (in basis point)
        uint256 liquidatorFeeRate;
        // Currencies accepted as collateral
        EnumerableSet.Bytes32Set collateralCurrencies;
        mapping(bytes32 ccy => address tokenAddress) tokenAddresses;
        // List of currency that the user has deposit amounts
        mapping(address user => EnumerableSet.Bytes32Set currency) usedCurrencies;
        mapping(bytes32 ccy => uint256 totalDepositAmount) totalDepositAmount;
        mapping(address user => mapping(bytes32 currency => uint256 depositAmount)) depositAmounts;
    }

    function slot() internal pure returns (Storage storage r) {
        bytes32 _slot = STORAGE_SLOT;
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := _slot
        }
    }
}
