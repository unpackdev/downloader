// SPDX-License-Identifier: MIT
// Copyright 2023 SolidifyLabs
pragma solidity ^0.8.15;

import "./Seller.sol";
import "./CallbackerWithAccessControl.sol";
import "./SupplyLimited.sol";
import "./InternallyPriced.sol";
import "./ByProjectId.sol";
import "./SellableERC721ACommonByProjectID.sol";

contract RoleGatedLimitedProjectId is FixedSupply, ImmutableCallbackerWithAccessControl, ByProjectId {
    bytes32 public constant PURCHASER_ROLE = keccak256("PURCHASER_ROLE");

    constructor(address admin, address steerer, ISellableByProjectID sellable_, uint64 numMax)
        ImmutableCallbackerWithAccessControl(admin, steerer, sellable_)
        FixedSupply(numMax)
    {
        _setRoleAdmin(PURCHASER_ROLE, DEFAULT_STEERING_ROLE);
    }

    function _checkAndModifyPurchase(address to, uint64 num, uint256 totalCost, bytes memory data)
        internal
        view
        virtual
        override(Seller, SupplyLimited)
        returns (address, uint64, uint256)
    {
        (to, num, totalCost) = Seller._checkAndModifyPurchase(to, num, totalCost, data);
        (to, num, totalCost) = SupplyLimited._checkAndModifyPurchase(to, num, totalCost, data);
        return (to, num, totalCost);
    }

    function _beforePurchase(address to, uint64 num, uint256 totalCost, bytes memory data)
        internal
        virtual
        override(Seller, SupplyLimited)
    {
        Seller._beforePurchase(to, num, totalCost, data);
        SupplyLimited._beforePurchase(to, num, totalCost, data);
    }

    function purchase(address to, uint128[] memory projectIds) external onlyRole(PURCHASER_ROLE) {
        _purchase(to, 0, projectIds);
    }
}
