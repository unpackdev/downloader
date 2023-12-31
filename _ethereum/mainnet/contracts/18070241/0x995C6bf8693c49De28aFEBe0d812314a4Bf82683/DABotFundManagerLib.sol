// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DABotCommon.sol"; 
import "./IBotBenefitciary.sol"; 

struct FundManagementData {
    address[] benefitciaries;
}

address constant BOT_CREATOR_BENEFITCIARY = address(1);
address constant GOV_USER_BENEFITCIARY = address(2);
address constant STAKE_USER_BENEFITCIARY = address(3);

library DABotFundManagerLib {
    bytes32 constant FUND_MANAGER_STORAGE_POSITION = keccak256("fundmanager.dabot.storage");


    function fundData() internal pure returns(FundManagementData storage ds) {
        bytes32 position = FUND_MANAGER_STORAGE_POSITION;
        assembly {
            ds.slot :=  position
        }
    }

    function benefitciaryName(address benefitciary) internal view returns(string memory) {
        if (benefitciary == BOT_CREATOR_BENEFITCIARY)
            return "Bot Creator";
        if (benefitciary == GOV_USER_BENEFITCIARY)
            return "Governance Users";
        if (benefitciary == STAKE_USER_BENEFITCIARY)
            return "Stake Users";
        return IBotBenefitciary(benefitciary).name();
    }

    function benefitciaryShortName(address benefitciary) internal view returns(string memory) {
        if (benefitciary == BOT_CREATOR_BENEFITCIARY)
            return "Bot Creator";
        if (benefitciary == GOV_USER_BENEFITCIARY)
            return "Gov. Users";
        if (benefitciary == STAKE_USER_BENEFITCIARY)
            return "Stake Users";
        return IBotBenefitciary(benefitciary).shortName();
    }

    function addBenefitciary(FundManagementData storage ds, address benefitciary) internal {
        ds.benefitciaries.push(benefitciary);
    }
}