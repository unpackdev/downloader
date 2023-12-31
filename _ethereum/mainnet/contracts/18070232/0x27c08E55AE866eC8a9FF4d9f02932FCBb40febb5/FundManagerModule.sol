// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./IConfigurator.sol";
import "./Errors.sol";
import "./RoboFiAddress.sol";
import "./DABotCommon.sol";
import "./DABotModule.sol";
import "./IVicsExchange.sol";
import "./IBotVault.sol";
import "./IFundManager.sol";
import "./IDABotFundManagerModule.sol";
import "./DABotSettingLib.sol";
import "./DABotStakingLib.sol";
import "./DABotControllerLib.sol";
import "./DABotFundManagerLib.sol";

abstract contract FundManagerModule is DABotModule, IDABotFundManagerModuleEvent {
    using DABotTemplateControllerLib for BotTemplateController;
    using DABotSettingLib for BotSetting;
    using DABotStakingLib for BotStakingData;
    using DABotMetaLib for BotMetaData;
    using DABotFundManagerLib for FundManagementData;
    using RoboFiAddress for IERC20;

    bytes4 constant WARMUP_VAULT = 0x5f0378a7; // warmup.vault
    bytes4 constant REGULAR_VAULT = 0x3e472239; //regular.vault
    bytes4 constant VIP_VAULT = 0x2c52665a; // vip.vault

    IBotVaultManager internal immutable vaultManager;

    constructor(IBotVaultManager _vault) {
        vaultManager = _vault;
    }

    modifier fundManagerOnly() {
        require(_msgSender() == address(_fundManager()), Errors.CFMOD_CALLER_IS_NOT_FUND_MANAGER);
        _;
    }

    function _onRegister(address moduleAddress) internal override {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        ds.registerModule(IDABotFundManagerModuleID, moduleAddress); 
        _registerSelectors(ds);
        emit ModuleRegistered("IDABotFundManagerModule", IDABotFundManagerModuleID, moduleAddress);
    }

    function _registerSelectors(BotTemplateController storage ds) internal virtual {
        bytes4[7] memory selectors =  [
            IDABotFundManagerModule.benefitciaries.selector,
            IDABotFundManagerModule.resetBenefitciaries.selector,
            IDABotFundManagerModule.addBenefitciary.selector,
            IDABotFundManagerModule.award.selector,
            IDABotFundManagerModule.pendingStakeReward.selector,
            IDABotFundManagerModule.pendingGovernReward.selector,
            IDABotFundManagerModule.withdrawToken.selector
        ];
        for (uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = IDABotFundManagerModuleID;
    } 

    function _initialize(bytes calldata) internal override {
        _resetBenefitciaries();
    }

    function resetBenefitciaries() external onlyBotOwner {
        _resetBenefitciaries();
    }

    function _resetBenefitciaries() private {
        BotMetaData storage meta = DABotMetaLib.metadata();
        FundManagementData storage fund = DABotFundManagerLib.fundData();
        delete fund.benefitciaries;
        BenefitciaryInfo[] memory _benefitciaries = IDABotFundManagerModule(meta.botTemplate).benefitciaries();
        for (uint i = 0; i < _benefitciaries.length; i++)
            fund.addBenefitciary(_benefitciaries[i].account);
    }

    function addBenefitciary(address benefitciary) external onlyBotOwner {
        FundManagementData storage fund = DABotFundManagerLib.fundData();
        for (uint i = 0; i < fund.benefitciaries.length; i++)
            require(fund.benefitciaries[i] != benefitciary, Errors.CFMOD_DUPLICATED_BENEFITCIARY);
        fund.benefitciaries.push(benefitciary);

        emit AddBenefitciary(benefitciary);
    }

    function benefitciaries() external view returns(BenefitciaryInfo[] memory result) {
        FundManagementData storage data = DABotFundManagerLib.fundData();
        result = new BenefitciaryInfo[](data.benefitciaries.length);
        uint profitSharing = DABotSettingLib.setting().profitSharing;

        for (uint i = 0; i < data.benefitciaries.length; i++) {
            address account = data.benefitciaries[i];
            result[i] = BenefitciaryInfo(
                    account,
                    DABotFundManagerLib.benefitciaryName(account),
                    DABotFundManagerLib.benefitciaryShortName(account),
                    profitSharing & 0xffff
                );
            profitSharing = profitSharing >> 16;
        }
    }

    function award(AwardingDetail[] calldata data) external virtual {
       _distributeReward(data);
    }

    function _distributeReward(AwardingDetail[] calldata data) internal {
        BotStakingData storage ds = DABotStakingLib.staking();
        uint[] memory totalStakes = new uint[](data.length);
        uint[] memory certTokenValues = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            _updatePnl(data[i]);
            IDABotCertToken certToken = ds.certificateOf(IRoboFiERC20(data[i].asset));
            totalStakes[i] = certToken.totalStake();
            certTokenValues[i] = certToken.value(1 ether);
        }
        emit Award(data, totalStakes, certTokenValues);
    }

    function pendingStakeReward(address account, IRoboFiERC20[] memory assets, 
        bytes memory subVaults) external view returns(StakingReward[] memory result) 
    {
        BotStakingData storage ds = DABotStakingLib.staking();
        if (assets.length == 0) 
            assets = ds.assets;
        if (subVaults.length == 0) 
            subVaults = abi.encodePacked(uint8(0), uint8(1), uint8(2));

        result = new StakingReward[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            result[i].asset = address(assets[i]);
            uint vID = vaultManager.vaultId(ds.portfolio[assets[i]].certToken, 0);
            for (uint j = 0; j < subVaults.length; j++) {
                uint8 x = uint8(subVaults[j]);
                result[i].amount += vaultManager.pendingReward(vID + uint(x), account);
            }
        }
    }

    function pendingGovernReward(address account, bytes memory subVaults) external view returns(uint result) {
        if (subVaults.length == 0) 
            subVaults = abi.encodePacked(uint8(0), uint8(1));
        result = 0;
        uint vID = vaultManager.vaultId(DABotMetaLib.metadata().gToken, 1);
        for (uint i = 0; i < subVaults.length; i++) {
            uint8 x = uint8(subVaults[i]);
            result += vaultManager.pendingReward(vID + uint(x), account);
        }
    }

    function withdrawToken(address asset, address to) external onlyBotOwner {
        uint balance = IERC20(asset).balanceOf(address(this));
        if (balance > 0)
            IERC20(asset).transfer(to, balance);
    }

    function _safeTransfer(IERC20 asset, address to,  uint amount) internal virtual {
       asset.safeTransferFrom(msg.sender, to, amount);
    }

    function _updatePnl(AwardingDetail calldata pnl) internal {
        BotStakingData storage ds = DABotStakingLib.staking();
        IDABotCertToken certToken = ds.certificateOf(IRoboFiERC20(pnl.asset));
        if (address(certToken) == address(0)) 
            revert(string(
                abi.encodePacked(Errors.CFMOD_INVALID_CERTIFICATE_OF_ASSET, " ", Strings.toHexString(uint160(pnl.asset), 20))));
        IERC20 asset = IERC20(pnl.asset);
        
        if (pnl.compound > 0) {
            if (pnl.compoundMode == 0) 
                _safeTransfer(asset, address(certToken), pnl.compound);
            certToken.compound(pnl.compound, pnl.compoundMode == 0);
            
            emit AwardCompound(address(asset), pnl.compound, pnl.compoundMode);
        }
        if (pnl.reward > 0) {
            FundManagementData storage fund = DABotFundManagerLib.fundData(); 
            uint128 shareScheme = DABotSettingLib.setting().profitSharing;
            uint total = 0;
            for(uint i = 0; i < fund.benefitciaries.length; i++) {
                if (fund.benefitciaries[i] != address(0)) 
                    total += shareScheme & 0xffff;
                shareScheme = shareScheme >> 16;
            }
            shareScheme = DABotSettingLib.setting().profitSharing;
            for(uint i = 0; i < fund.benefitciaries.length; i++) {
                if (fund.benefitciaries[i] != address(0)) {
                    _awardSingle(address(certToken), asset, fund.benefitciaries[i], pnl.reward, (shareScheme & 0xffff), total);
                }
                shareScheme = shareScheme >> 16;
            }
        }
    }

    function _awardSingle(address certToken, IERC20 asset, address benefitciary, uint reward, uint share, uint totalShare) internal {
        BotMetaData storage meta = DABotMetaLib.metadata();
        uint amount = reward * share / totalShare;

        if (benefitciary == BOT_CREATOR_BENEFITCIARY) {
            _safeTransfer(asset, meta.botOwner, amount);
            emit AwardBenefitciary(benefitciary, address(asset), address(asset), amount, share, totalShare);
            return;
        }

        if (benefitciary == STAKE_USER_BENEFITCIARY) {
            uint vID = vaultManager.vaultId(certToken, 0);
            _safeTransfer(asset, address(vaultManager), amount);
            _awardVault(vID, 3, amount, [uint(80), 100, 120]);
            emit AwardBenefitciary(benefitciary, address(asset), address(asset), amount, share, totalShare);
            return;
        }

        IConfigurator config = meta.configurator();
        IERC20 vics = IERC20(config.addressOf(AddressBook.ADDR_VICS));
        _safeTransfer(asset, address(this), amount);
        uint vicsAmount = _exchangeToVICS(config, asset, amount);

        if (benefitciary == GOV_USER_BENEFITCIARY) {
            IERC20 gToken = meta.governToken();
            uint vID = vaultManager.vaultId(address(gToken), 1);

            vics.transfer(address(vaultManager), vicsAmount);
            _awardVault(vID, 2, vicsAmount, [uint(100), 120, 0]);
        } else {
            vics.transfer(benefitciary, vicsAmount);
            IBotBenefitciary(benefitciary).onAward(vicsAmount);
        }

        emit AwardBenefitciary(benefitciary, address(asset), address(vics), vicsAmount, share, totalShare);
    }

    function _awardVault(uint vID, uint numVault, uint amount, uint[3] memory weight) internal {
        uint[] memory deposit = new uint[](numVault);
        uint total;
        for (uint i = 0; i < numVault; i++) {
            deposit[i] = vaultManager.getVaultInfo(vID + i, address(this)).totalDeposit * weight[i];
            total += deposit[i];
        }
        if (total == 0)
            return;
        for (uint i = 0; i < numVault; i++) {
            vaultManager.updateReward(vID + i, deposit[i] * amount / total); 
        }
    }

    function _fundManager() internal view returns(IFundManager manager) {
        manager = IFundManager(configurator().addressOf(AddressBook.ADDR_CEX_FUND_MANAGER));
        require(address(manager) != address(0), Errors.CM_CEX_FUND_MANAGER_IS_NOT_CONFIGURED);
    }

    function _exchangeToVICS(IConfigurator config, IERC20 asset, uint amount) private returns(uint) {
        IVicsExchange xchg = IVicsExchange(config.addressOf(AddressBook.ADDR_VICS_EXCHANGE));
        require(address(xchg) != address(0), Errors.CM_VICS_EXCHANGE_IS_NOT_CONFIGURED);
        asset.approve(address(xchg), amount);

        return xchg.swap(asset, amount);
    }
}
