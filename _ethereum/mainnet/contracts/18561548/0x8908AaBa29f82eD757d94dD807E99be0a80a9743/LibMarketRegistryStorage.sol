// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library LibMarketRegistryStorage {
    bytes32 constant MARKET_REGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.MARKETREGISTRY.storage");

    struct MarketRegistryStorage {
        uint256 allowedLoanActivateLimit;
        uint256 minLoanAmountAllowed;
        uint256 ltvPercentage;
        uint256 multiCollateralLimit;
        mapping(address => bool) whitelistAddress;
    }

    function marketRegistryStorage()
        internal
        pure
        returns (MarketRegistryStorage storage es)
    {
        bytes32 position = MARKET_REGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
