// SPDX-License-Identifier: MIT
// Copyright 2023 SolidifyLabs
pragma solidity >=0.8.0 <0.9.0;

import "./Seller.sol";
import "./SellableERC721ACommonByProjectID.sol";

abstract contract ByProjectId is Seller {
    function _purchase(address to, uint256 externalTotalCost, uint128[] memory projectIds) internal virtual {
        _purchase(
            to, uint64(projectIds.length), externalTotalCost, PurchaseByProjectIDLib.encodePurchaseData(projectIds)
        );
    }
}
