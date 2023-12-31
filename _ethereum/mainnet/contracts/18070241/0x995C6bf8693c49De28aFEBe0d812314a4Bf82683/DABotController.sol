// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./IInitializable.sol";
import "./Errors.sol";
import "./IDABot.sol";
import "./IDABotController.sol";
import "./IDABotModule.sol";
import "./IDABotGovernToken.sol";
import "./DABotSettingLib.sol";
import "./DABotStakingLib.sol";
import "./DABotControllerLib.sol";

contract DABotModuleController is IInitializable, Context, IDABotControllerEvent {

    using DABotTemplateControllerLib for BotTemplateController;
    using DABotMetaLib for BotMetaData;
    using DABotStakingLib for BotStakingData;
    using DABotSettingLib for BotSetting;

    constructor(uint8 botType, string memory name, string memory version) {
        BotCoreData storage ds = DABotTemplateControllerLib.coredata();
        ds.metadata = BotMetaData(
            name,
            '',
            version,
            botType,
            false,  // abandoned
            true,   // is template
            true,   // initialized
            _msgSender(), // owner
            address(0),   // botManager
            address(0),   // botTemplate
            address(0)    // gToken
        );
    }

    modifier onlyTemplate() {
        require(DABotMetaLib.metadata().isTemplate, Errors.BCMOD_CANNOT_CALL_TEMPLATE_METHOD_ON_BOT_INSTANCE); 
        _;
    }

    modifier onlyOwner() {
        BotMetaData storage ds = DABotMetaLib.metadata();
        require(_msgSender() == ds.botOwner, Errors.BCMOD_CALLER_IS_NOT_OWNER);
        _;
    }

    function registerModule(address moduleHandler) public onlyTemplate onlyOwner {
        IDABotModule _module = IDABotModule(moduleHandler);
        (string memory _name, string memory _version, bytes32 _moduleId) = _module.moduleInfo();

        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        bool moduleExisted = ds.moduleAddresses[_moduleId] != address(0);

        (bool success, bytes memory result) = 
            moduleHandler.delegatecall(abi.encodeWithSelector(IDABotModule.onRegister.selector, moduleHandler));
        
        require(success, string(abi.encodePacked("Controller: module ", _name, ' registration error: ',  result)));

        if (!moduleExisted) 
            ds.modules.push(_moduleId);
        
        emit ModuleRegistered(_moduleId, moduleHandler, _name, _version);
    }

    function updateModuleHandler(bytes32 moduleId, address newModuleAddress) public onlyTemplate onlyOwner {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        bool moduleExisted = ds.moduleAddresses[moduleId] != address(0);
        address oldModuleAddress = ds.registerModule(moduleId, newModuleAddress); 
        if (!moduleExisted)
            ds.modules.push(moduleId);
        emit ModuleHandlerChanged(moduleId, oldModuleAddress, newModuleAddress);
    }

    function module(bytes32 moduleId) external view onlyTemplate returns(address) {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        return ds.module(moduleId);
    }

    function moduleOfSelector(bytes4 selector) public view onlyTemplate returns(address) {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        return ds.moduleOfSelector(selector);
    }

    function init(bytes calldata data) external payable override {
        BotMetaData storage ds = DABotMetaLib.metadata();
        require(!ds.initialized, Errors.CM_CONTRACT_HAS_BEEN_INITIALIZED);
       
        (BotMetaData memory meta, BotModuleInitData[] memory initData) = 
            abi.decode(data, (BotMetaData, BotModuleInitData[]));

        BotMetaData memory templateMeta = IDABot(meta.botTemplate).metadata();

        ds.name = meta.name;
        ds.symbol = meta.symbol;
        ds.version = meta.version;
        ds.botType = templateMeta.botType;
        ds.botOwner = meta.botOwner;
        ds.botManager = meta.botManager;
        ds.botTemplate = meta.botTemplate;
                
        for(uint i = 0; i < initData.length; i++) {
            address moduleAddress = ds.module(initData[i].moduleId);
            if (moduleAddress == address(0))
                revert(string(abi.encodePacked("Controller: module #", i, "(", Strings.toHexString(uint256(initData[i].moduleId), 32) ,") not found"))); 

            (bool success, bytes memory result) = moduleAddress.delegatecall(abi.encodeWithSelector(IDABotModule.onInitialize.selector, initData[i].data));
            if (!success) {
                revert(string(abi.encodePacked(
                        string(result), 
                        ' (module ', Strings.toString(i + 1), '/', Strings.toString(initData.length), ' ', 
                        Strings.toHexString(uint160(moduleAddress), 20), ")")));
            }
        }
        ds.initialized = true;
    }

    fallback() external payable {
        __forwardCall();
    }

    function __findImplementation() internal view returns(address) {
        BotMetaData storage meta = DABotMetaLib.metadata();
        address moduleAddress;
        if (meta.botTemplate == address(0)) {
            moduleAddress = moduleOfSelector(msg.sig);
        } else {
            moduleAddress = DABotModuleController(payable(meta.botTemplate)).moduleOfSelector(msg.sig);
        }
        if (moduleAddress == address(0)) {
            revert(string(abi.encodePacked(Errors.BCMOD_MODULE_HANDLER_NOT_FOUND_FOR_METHOD_SIG, " ", Strings.toHexString(uint32(msg.sig), 4)))); 
        }
        return moduleAddress;
    }

    function __forwardCall() internal {
        address handler = __findImplementation();
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), handler, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}

    function rescueToken(address token) external payable onlyOwner {
        if (token == address(0))
            payable(owner()).transfer(address(this).balance);
        else {
            IRoboFiERC20 erc20 = IRoboFiERC20(token);
            erc20.transfer(owner(), erc20.balanceOf(address(this)));
        }
    }

    function qualifiedName() external view returns(string memory) {
        BotMetaData storage meta = DABotMetaLib.coredata().metadata;
        if (meta.isTemplate)
            return string(abi.encodePacked(meta.name,":",meta.version));
        return string(abi.encodePacked(meta.symbol,":",meta.name));
    }

    function metadata() external view returns(BotMetaData memory) {
        return DABotMetaLib.coredata().metadata;
    }

    function governToken() external view returns(IDABotGovernToken) {
        return IDABotGovernToken(DABotMetaLib.metadata().gToken);
    }

    function setting() external view returns(BotSetting memory) {
        return DABotSettingLib.setting();
    }

    function botDetails() external view returns(BotDetail memory output) {
        BotMetaData storage meta = DABotMetaLib.metadata();
        BotStakingData storage staking = DABotStakingLib.staking();
        BotSetting storage _setting = DABotSettingLib.setting();

        BotMetaData memory templateMeta = DABotModuleController(payable(meta.botTemplate)).metadata();
        IDABotGovernToken gToken = IDABotGovernToken(meta.gToken);

        output.botAddress = address(this);
        output.template = meta.botTemplate;
        output.botSymbol = meta.symbol;
        output.botName = meta.name;
        output.status = _setting.status();
        output.botType = templateMeta.botType;
        output.governToken = meta.gToken;
        output.templateName = templateMeta.name; 
        output.templateVersion = templateMeta.version;
        output.iboStartTime = _setting.iboStartTime();
        output.iboEndTime = _setting.iboEndTime();
        output.warmup = _setting.warmupTime();
        output.cooldown = _setting.cooldownTime();
        output.priceMul = _setting.priceMultiplier();
        output.commissionFee = _setting.commission();
        output.profitSharing = _setting.profitSharing;
        output.initDeposit = _setting.initDeposit;
        output.initFounderShare = _setting.initFounderShare;
        output.maxShare = _setting.maxShare;
        output.iboShare = _setting.iboShare;
        output.circulatedShare = gToken.totalSupply();
        output.userShare = gToken.balanceOf(_msgSender());
        output.portfolio = staking.portfolioDetails();
    }

    function owner() public view returns(address) {
        return DABotMetaLib.metadata().botOwner;
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), Errors.BCMOD_NEW_OWNER_IS_ZERO);
        _transferOwnership(newOwner);
    }

    function abandon(bool value) external onlyOwner {
        DABotMetaLib.metadata().abandoned = value;
        emit BotAbandoned(value);
    }

    function modulesInfo() external view returns(BotModuleInfo[] memory result) {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        result = new BotModuleInfo[](ds.modules.length);
        for (uint i = 0; i < ds.modules.length; i++) {
            IDABotComponent moduleHandler = IDABotComponent(ds.moduleAddresses[ds.modules[i]]);
            (string memory _name, string memory _version,) = moduleHandler.moduleInfo();
            result[i] = BotModuleInfo(_name, _version, ds.moduleAddresses[ds.modules[i]]);
        }
    }

    function moduleHandlerInfo(bytes32[] calldata ids) external view returns(address[] memory result) {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        result = new address[](ids.length);
        for (uint i = 0; i < ids.length; i++)
            result[i] = ds.moduleAddresses[ids[i]];
    }

    function _transferOwnership(address newOwner) internal {
        BotMetaData storage ds = DABotMetaLib.metadata();
        address oldOwner = ds.botOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        ds.botOwner = newOwner;
    }
}