// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DABotCommon.sol";
import "./DABotModule.sol";
import "./IDABotGovernToken.sol";
import "./IDABotGovernModule.sol";
import "./IBotVault.sol";
import "./IConfigurator.sol";
import "./DABotStakingLib.sol";
import "./DABotSettingLib.sol";
import "./DABotControllerLib.sol";
import "./DABotGovernLib.sol";

contract DABotGovernModule is DABotModule, IDABotGovernModuleEvent {

    using DABotTemplateControllerLib for BotTemplateController;
    using DABotSettingLib for BotSetting;
    using DABotStakingLib for BotStakingData;
    using DABotMetaLib for BotMetaData;

    bytes4 constant REGULAR_VAULT = 0x3e472239; //regular.vault
    bytes4 constant VIP_VAULT = 0x2c52665a; // vip.vault

    IBotVaultManager private immutable vaultManager;

    constructor(IBotVaultManager vault) {
        vaultManager = vault;
    }

    function _onRegister(address moduleAddress) internal override {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        ds.registerModule(IDABotGovernModuleID, moduleAddress); 

        bytes4[11] memory selectors =  [
            IDABotGovernModule.createGovernVaults.selector,
            IDABotGovernModule.governVaults.selector,
            IDABotGovernModule.harvestGovernanceReward.selector,
            IDABotGovernModule.governanceReward.selector,
            IDABotGovernModule.mintableShare.selector,
            IDABotGovernModule.iboMintableShareDetail.selector,
            IDABotGovernModule.calcOutShare.selector,
            IDABotGovernModule.shareOf.selector,
            IDABotGovernModule.mintShare.selector,
            IDABotGovernModule.burnShare.selector,
            IDABotGovernModule.snapshot.selector
        ];
        for (uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = IDABotGovernModuleID;

        emit ModuleRegistered("IDABotGovernModuleID", IDABotGovernModuleID, moduleAddress);
    }

    function _initialize(bytes calldata) internal override {
        BotMetaData storage meta = DABotMetaLib.metadata();
        meta.gToken = meta.deployGovernanceToken();
    }

    function moduleInfo() external pure override returns(string memory name, string memory version, bytes32 moduleId) {
        name = "DABotGovernModule";
        version = "v0.1.220101";
        moduleId = IDABotGovernModuleID;
    }

    function createGovernVaults() external onlyBotManager {
        BotMetaData storage meta = DABotMetaLib.metadata();
        IDABotGovernToken gToken = meta.governToken();
        IERC20 asset = gToken.asset();
        vaultManager.createVault(VaultData(address(gToken), asset, address(this), 1, REGULAR_VAULT));
        uint vID = vaultManager.createVault(VaultData(address(gToken), asset, address(this), 2, VIP_VAULT));
        BotSetting storage setting = DABotSettingLib.setting();

        gToken.mint(address(vaultManager), setting.initFounderShare);
        uint iboEndTime = setting.iboEndTime();
        uint lockTime = iboEndTime > block.timestamp ? iboEndTime - block.timestamp : 0;
        vaultManager.delegateDeposit(vID, address(0), meta.botOwner, setting.initFounderShare, lockTime);
    }

    function governVaults(address account) external view returns(VaultInfo[] memory result) {
        IDABotGovernToken gToken = DABotMetaLib.metadata().governToken();
        uint vID = vaultManager.vaultId(address(gToken), 1);
        result = new VaultInfo[](2);
        result[0] = vaultManager.getVaultInfo(vID, account);
        result[1] = vaultManager.getVaultInfo(vID + 1, account);
    }

    function harvestGovernanceReward() external {
        IDABotGovernToken gToken = DABotMetaLib.metadata().governToken();
        uint vID = vaultManager.vaultId(address(gToken), 1);
        vaultManager.claimReward(vID, msg.sender);
        vaultManager.claimReward(vID + 1, msg.sender);
    }

    function governanceReward(address account) external view returns(uint) {
        IDABotGovernToken gToken = DABotMetaLib.metadata().governToken();
        uint vID = vaultManager.vaultId(address(gToken), 1);
        return vaultManager.pendingReward(vID, account)
                + vaultManager.pendingReward(vID + 1, account);
    }

    /**
    @dev Calculates the shares (g-tokens) available for purchasing for the specified account.

    During the IBO time, the amount of available shares for purchasing is derived from
    the staked asset (refer to the Concept Paper for details). 
    
    After IBO, the availalbe amount equals to the uncirculated amount of goveranance tokens.
     */
    function mintableShare(address account) public view returns(uint result) {

        BotSetting storage _setting = DABotSettingLib.setting();
        BotStakingData storage staking = DABotStakingLib.staking();
        IDABotGovernToken gToken =   DABotMetaLib.metadata().governToken();

        if (block.timestamp < _setting.iboStartTime()) return 0; 
        if (block.timestamp > _setting.iboEndTime()) return _setting.maxShare - gToken.totalSupply();

        uint totalWeight = 0;
        uint totalPoint = 0;
        for (uint i = 0; i < staking.assets.length; i ++) {
            IRoboFiERC20 asset = staking.assets[i];
            PortfolioAsset storage pAsset = staking.portfolio[asset];
            totalPoint += staking.stakeBalanceOf(account, asset) * pAsset.weight * 1e18 / pAsset.iboCap;
            totalWeight += pAsset.weight;
        }

        uint currentBalance = shareOf(account);

        result = (_setting.iboShare) * totalPoint / totalWeight / 1e18;

        if (result > currentBalance)
            result -= currentBalance;
        else 
            result = 0;
    }

    function iboMintableShareDetail(address account) view public returns(MintableShareDetail[] memory result) {
        BotStakingData storage staking = DABotStakingLib.staking(); 

        result = new MintableShareDetail[](staking.assets.length);
        uint totalWeight = 0;
        
        for (uint i = 0; i < staking.assets.length; i ++) {
            IRoboFiERC20 asset = staking.assets[i];
            PortfolioAsset storage pAsset = staking.portfolio[asset];
            result[i].asset = address(asset);
            result[i].stakeAmount = staking.stakeBalanceOf(account, asset);
            result[i].weight = pAsset.weight;
            result[i].iboCap = pAsset.iboCap;

            totalWeight += pAsset.weight;
        }

        BotSetting storage _setting = DABotSettingLib.setting();
        for (uint i = 0; i < staking.assets.length; i++) {
            result[i].mintableShare = (_setting.iboShare) * result[i].stakeAmount 
                                        * result[i].weight 
                                        / (totalWeight * result[i].iboCap);
        }
    }

    function calcOutShare(address account, uint vicsAmount) public view virtual returns(uint payment, uint shares, uint fee) {
        BotSetting storage _setting = DABotSettingLib.setting();

        uint priceMultipler = 100; 
        uint commission = 0;

        if (block.timestamp >= _setting.iboEndTime()) {
            priceMultipler = _setting.priceMultiplier();
            commission = _setting.commission();
        }

        uint outAmount = (10000 - commission) * vicsAmount *  _setting.initFounderShare / priceMultipler / _setting.initDeposit / 100; 
        uint maxAmount = mintableShare(account);

        if (outAmount <= maxAmount) {
            shares = outAmount;
            fee = vicsAmount * commission / 10000; 
            payment = vicsAmount - fee;
        } else {
            shares = maxAmount;
            payment = maxAmount * _setting.initDeposit * priceMultipler / _setting.initFounderShare / 100;
            fee = payment * commission / (10000 - commission);
        }
    }

    function shareOf(address account) public view returns(uint) {
        IDABotGovernToken gToken = DABotMetaLib.metadata().governToken();
        uint vID = vaultManager.vaultId(address(gToken), 1);
        return  gToken.balanceOf(account) +
                vaultManager.balanceOf(vID, account)  + // regular vault
                vaultManager.balanceOf(vID + 1, account); // vip vault
    }


    function mintShare(uint vicsAmount) public virtual activeBot whitelistCheck(_msgSender(), WHITELIST_CHECK_GOV_USERS) {
        _mintShare(_msgSender(), vicsAmount);
    }

    function burnShare(uint amount) public virtual {
        IDABotGovernToken gToken = DABotMetaLib.metadata().governToken();
        gToken.burn(amount);
    }

    function _mintShare(address account, uint vicsAmount) internal virtual {
        BotMetaData storage meta = DABotMetaLib.metadata();
        IDABotManager botManager = meta.manager();
        IConfigurator config = botManager.configurator();
        IRoboFiERC20 vicsToken = IRoboFiERC20(config.addressOf(AddressBook.ADDR_VICS));

        (uint payment, uint shares, uint fee) = calcOutShare(account, vicsAmount);
        if (shares == 0)
            return;
        IDABotGovernToken gToken = meta.governToken();
        if (fee > 0) {
            address taxAddress = config.addressOf(AddressBook.ADDR_TAX);
            if (taxAddress == address(0))
                taxAddress = address(gToken);
            vicsToken.transferFrom(account, taxAddress, fee); 
        }
        vicsToken.transferFrom(account, address(gToken), payment);
        gToken.mint(address(vaultManager), shares);

        uint iboEndTime = DABotSettingLib.setting().iboEndTime();
        uint vID = vaultManager.vaultId(address(gToken), 0);
        if (block.timestamp < iboEndTime) 
            // move minted token to VIP vault if it's in-IBO or pre-IBO time
            vaultManager.delegateDeposit(vID + 2, address(0), account, shares, iboEndTime - block.timestamp);
        else
            // move minted token to regular vault for after-IBO time
            vaultManager.delegateDeposit(vID + 1, address(0), account, shares, 0);

        emit MintGToken(account, payment + fee, fee, shares, gToken.value(1 ether)); 
    }

    function snapshot() external onlyBotManager {
        IDABotGovernToken gToken = DABotMetaLib.metadata().governToken();
        gToken.snapshot();
        uint vID = vaultManager.vaultId(address(gToken), 1);
        vaultManager.snapshot(vID);
    }
}