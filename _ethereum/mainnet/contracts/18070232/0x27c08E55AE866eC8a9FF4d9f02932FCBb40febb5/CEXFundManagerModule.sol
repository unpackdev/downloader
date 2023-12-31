// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FundManagerModule.sol";

contract CEXFundManagerModule is FundManagerModule {
    constructor(IBotVaultManager _vault ) FundManagerModule(_vault) {
    }

    function _registerSelectors(BotTemplateController storage ds) internal override {
        super._registerSelectors(ds);
        bytes4[1] memory selectors =  [
            CEXFundManagerModule.distributeReward.selector
        ];
        for (uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = IDABotFundManagerModuleID;
    } 

    function moduleInfo() external pure override returns(string memory name, string memory version, bytes32 moduleId) {
        name = "CEXFundManagerModule";
        version = "v0.1.220501";
        moduleId = IDABotFundManagerModuleID;
    }


    function award(AwardingDetail[] calldata data) external override onlyBotOwner {
        _fundManager().createAwardingRequest(address(this), data);
    }

    function distributeReward(AwardingDetail[] calldata data) external {
        _distributeReward(data);
    }
}
