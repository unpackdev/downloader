// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./ITreasuryConfig.sol";
import "./Governable.sol";

contract TreasuryConfig is ITreasuryConfig, Governable {
    // ============ Mutable Storage ============

    address payable public override treasury;
    address public override distributionModel;

    // ============ Constructor ============

    constructor(
        address owner_,
        address distributionModel_,
        address payable treasury_
    ) Governable(owner_) {
        treasury = treasury_;
        distributionModel = distributionModel_;
    }

    // ============ Configuration ============

    function setTreasury(address payable newTreasury) public onlyGovernance {
        treasury = newTreasury;
    }

    function setDistributionModel(address newDistributionModel)
        public
        onlyGovernance
    {
        distributionModel = newDistributionModel;
    }
}
