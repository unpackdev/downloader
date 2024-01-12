// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "./IHYFI_Whitelist.sol";
import "./IHYFI_Referrals.sol";
import "./HYFI_PriceCalculator.sol";

contract HYFI_PriceCalculatorV1 is HYFI_PriceCalculator {
    mapping(uint256 => uint256[]) public stagesBulkDiscounts;
    mapping(uint256 => uint256) public stagesWhitelistDiscounts;

    function setStagesDiscounts(
        uint256 stage,
        uint256[] memory bulkDiscounts,
        uint256 whitelistDiscount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stagesBulkDiscounts[stage] = bulkDiscounts;
        stagesWhitelistDiscounts[stage] = whitelistDiscount;
    }

    function discountPercentageCalculator(uint256 unitAmount, address buyer)
        public
        view
        virtual
        override
        returns (uint256 discountPrecentage)
    {
        return discountPercentageCalculator(unitAmount, buyer, 0);
    }

    function discountPercentageCalculator(
        uint256 unitAmount,
        address buyer,
        uint256 stage
    ) public view virtual returns (uint256 discountPrecentage) {
        if (unitAmount <= 4) {
            discountPrecentage = stagesBulkDiscounts[stage][0];
        } else if (unitAmount <= 50) {
            discountPrecentage = stagesBulkDiscounts[stage][1];
        } else {
            discountPrecentage = stagesBulkDiscounts[stage][2];
        }
        if (whitelist.isWhitelisted(buyer)) {
            discountPrecentage += stagesWhitelistDiscounts[stage];
        }
        return discountPrecentage;
    }
}
