// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./Structs.sol";
import "./IProductViewEntry.sol";
import "./CegaStorage.sol";

contract ProductViewEntry is IProductViewEntry, CegaStorage {
    function getStrategyOfProduct(
        uint32 productId
    ) external view returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.strategyOfProduct[productId];
    }

    function getLatestProductId() external view returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.productIdCounter;
    }

    function getProductMetadata(
        uint32 productId
    ) external view returns (ProductMetadata memory) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.productMetadata[productId];
    }
}
