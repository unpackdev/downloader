// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Errors.sol";
import "./IDABotWhitelist.sol";
import "./DABotControllerLib.sol";
import "./DABotCommon.sol";
import "./DABotModule.sol";

contract DABotWhitelistModule is DABotModule, IDABotWhitelistModuleEvent {

    using DABotTemplateControllerLib for BotTemplateController;

    function _onRegister(address moduleAddress) internal override {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        ds.registerModule(IDABotWhitelistModuleID, moduleAddress); 
        bytes4[5] memory selectors =  [
            IDABotWhitelistModule.whitelistScope.selector,
            IDABotWhitelistModule.setWhitelistScope.selector,
            IDABotWhitelistModule.addWhitelist.selector,
            IDABotWhitelistModule.removeWhitelist.selector,
            IDABotWhitelistModule.isWhitelist.selector
        ];
        for (uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = IDABotWhitelistModuleID;

        emit ModuleRegistered("IDABotWhitelistModule", IDABotWhitelistModuleID, moduleAddress);
    }

    function _initialize(bytes calldata data) internal override {
    }

    function moduleInfo() external pure override returns(string memory name, string memory version, bytes32 moduleId) {
        name = "DABotWhitelistModule";
        version = "v0.1.211202";
        moduleId = IDABotWhitelistModuleID;
    }

    function whitelistScope() external view returns(uint) {
        BotWhitelistData storage data = DABotWhitelistLib.whitelist();
        return data.scope;
    }

    function setWhitelistScope(uint scope) external onlyBotOwner {
        BotWhitelistData storage data = DABotWhitelistLib.whitelist();
        data.scope = scope;
        emit WhitelistScope(scope);
    }

    function addWhitelist(address account, uint scope) external onlyBotOwner {
        require(account != address(0), Errors.BWL_ACCOUNT_IS_ZERO);
        BotWhitelistData storage data = DABotWhitelistLib.whitelist();
        data.whitelist[account] = scope;
        emit WhitelistAdd(account, scope);
    }

    function removeWhitelist(address account) external onlyBotOwner {
        require(account != address(0), Errors.BWL_ACCOUNT_IS_ZERO);
        BotWhitelistData storage data = DABotWhitelistLib.whitelist();
        data.whitelist[account] = 0;
        emit WhitelistRemove(account);
    }

    function isWhitelist(address account, uint scope) external view returns(bool) {
        require(account != address(0), Errors.BWL_ACCOUNT_IS_ZERO);
        return DABotWhitelistLib.isWhitelist(account, scope);
    }
}