// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC165.sol";
import "./DABotController.sol";
import "./IDABotSettingModule.sol";
import "./IDABotStakingModule.sol";
import "./IDABotGovernModule.sol";
import "./IDABotFundManagerModule.sol";
import "./IDABotFarmingModule.sol";
import "./IDABotWhitelist.sol";
import "./IDABot.sol";
import "./DABotCommon.sol";
import "./DABotFundManagerLib.sol";

contract DABot is DABotModuleController, IERC165 {

    using DABotFundManagerLib for FundManagementData;

    constructor(
        uint8 templateType,
        string memory templateName,
        string memory version,
        bytes32[] memory handlerIds,
        address[] memory handlerImpls,
        address[] memory funcModules,
        address[] memory beneficiaries
    ) DABotModuleController(templateType, templateName, version)
    {
        for(uint i = 0; i < handlerIds.length; i++)
            updateModuleHandler(handlerIds[i], handlerImpls[i]);
        for(uint i = 0; i < funcModules.length; i++)
            registerModule(funcModules[i]);
        FundManagementData storage fundData = DABotFundManagerLib.fundData();
        for(uint i = 0; i < beneficiaries.length; i++)
            fundData.addBenefitciary(beneficiaries[i]);
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return (interfaceId == type(IERC165).interfaceId) ||
                (interfaceId == type(IDABot).interfaceId)
        ;
    }
}