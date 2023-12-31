// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./SafeERC20.sol";
import "./Errors.sol";
import "./DABotCommon.sol";
import "./DABotModule.sol";
import "./IBotVault.sol";
import "./IDABotStakingModule.sol";
import "./DABotControllerLib.sol";
import "./DABotSettingLib.sol";
import "./DABotStakingLib.sol";

contract DABotStakingModule is DABotModule, IDABotStakingModuleEvent {
    using DABotStakingLib for BotStakingData;
    using DABotSettingLib for BotSetting;
    using DABotMetaLib for BotMetaData;
    using DABotTemplateControllerLib for BotTemplateController;
    using SafeERC20 for IERC20;

    IBotVaultManager private immutable vaultManager;

    bytes4 constant WARMUP_VAULT = 0x5f0378a7; // warmup.vault
    bytes4 constant REGULAR_VAULT = 0x3e472239; //regular.vault
    bytes4 constant VIP_VAULT = 0x2c52665a; // vip.vault

    constructor(IBotVaultManager _vault) {
        vaultManager = _vault;
    }

    function _onRegister(address moduleAddress) internal override {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        ds.registerModule(IDABotStakingModuleID, moduleAddress); 
        bytes4[22] memory selectors =  [
            IDABotStakingModule.portfolioDetails.selector,
            IDABotStakingModule.portfolioOf.selector,
            IDABotStakingModule.updatePortfolioAsset.selector,
            IDABotStakingModule.removePortfolioAsset.selector,
            IDABotStakingModule.createPortfolioVaults.selector,
            IDABotStakingModule.certificateVaults.selector,
            IDABotStakingModule.stakingReward.selector,
            IDABotStakingModule.harvestStakingReward.selector,
            IDABotStakingModule.upgradeVault.selector,
            IDABotStakingModule.getMaxStake.selector,
            IDABotStakingModule.stake.selector,
            IDABotStakingModule.unstake.selector,
            IDABotStakingModule.stakeBalanceOf.selector,
            IDABotStakingModule.warmupBalanceOf.selector,
            IDABotStakingModule.cooldownBalanceOf.selector,
            IDABotStakingModule.certificateOf.selector,
            IDABotStakingModule.assetOf.selector,
            IDABotStakingModule.isCertLocker.selector,
            IDABotStakingModule.warmupDetails.selector,
            IDABotStakingModule.cooldownDetails.selector,
            IDABotStakingModule.releaseWarmups.selector,
            IDABotStakingModule.releaseCooldowns.selector 
        ];
        for (uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = IDABotStakingModuleID;

        emit ModuleRegistered("IDABotStakingModule", IDABotStakingModuleID, moduleAddress);
    }

    function _initialize(bytes calldata data) internal override {
        PortfolioCreationData[] memory portfolio = abi.decode(data, (PortfolioCreationData[]));

        for(uint idx = 0; idx < portfolio.length; idx++) 
            updatePortfolioAsset(IRoboFiERC20(portfolio[idx].asset), portfolio[idx].cap, portfolio[idx].iboCap, portfolio[idx].weight);
    }

    function moduleInfo() external pure override returns(string memory name, string memory version, bytes32 moduleId) {
        name = "DABotStakingModule";
        version = "v0.1.211202";
        moduleId = IDABotStakingModuleID;
    }

    function portfolioDetails() external view returns(UserPortfolioAsset[] memory) {
        return DABotStakingLib.staking().portfolioDetails();
    }

    function portfolioOf(IRoboFiERC20 asset) external view returns(UserPortfolioAsset memory) {
        return DABotStakingLib.staking().portfolioOf(asset);
    }

    function updatePortfolioAsset(IRoboFiERC20 asset, uint maxCap, uint iboCap, uint weight) public onlyBotOwner {
        BotMetaData storage meta = DABotMetaLib.metadata();
        BotStakingData storage ds = DABotStakingLib.staking();
        BotSetting storage setting = DABotSettingLib.setting();
        PortfolioAsset storage pAsset = ds.portfolio[asset];
        require(address(asset) != address(0), Errors.BSTMOD_INVALID_PORTFOLIO_ASSET);

        bool newAsset = address(pAsset.certToken) == address(0);

        if (newAsset) {
            require(!meta.initialized || block.timestamp < setting.iboStartTime(), Errors.BSTMOD_PRE_IBO_REQUIRED);
            require(maxCap > 0, Errors.BSTMOD_CAP_IS_ZERO);
            require(weight > 0, Errors.BSTMOD_WERIGHT_IS_ZERO);
        }
        
        ds.updatePortfolioAsset(asset, maxCap, iboCap, weight);

        if (newAsset && meta.initialized)   
            // Only create vaults when bot is intialized and has be recognized by the bot manager.
            // Otherwise, the vault manager will reject the vault creation.
            _createVaults(pAsset.certToken);

        emit PortfolioUpdated(address(asset), address(pAsset.certToken), pAsset.cap, pAsset.iboCap, pAsset.weight);
    }

    function createPortfolioVaults() external onlyBotManager {
         BotStakingData storage ds = DABotStakingLib.staking();
         for (uint i = 0; i < ds.assets.length; i++) {
             _createVaults(ds.portfolio[ds.assets[i]].certToken);
         }
    }

    function certificateVaults(address certToken, address account) external view returns(VaultInfo[] memory result) {
        uint vID = vaultManager.vaultId(certToken, 0);
        result = new VaultInfo[](3);
        result[0] = vaultManager.getVaultInfo(vID, account);
        result[1] = vaultManager.getVaultInfo(vID + 1, account);
        result[2] = vaultManager.getVaultInfo(vID + 2, account);
    }

    function harvestStakingReward() external {
        BotStakingData storage ds = DABotStakingLib.staking();
        for (uint i = 0; i < ds.assets.length; i++) {
            _harvestStakingReward(ds.portfolio[ds.assets[i]].certToken);
        }
    }

    function stakingReward(address certToken, address account) external view returns(uint) {
        uint vID = vaultManager.vaultId(certToken, 0);
        return vaultManager.pendingReward(vID, account)
            + vaultManager.pendingReward(vID + 1, account)
            + vaultManager.pendingReward(vID + 2, account);
    }

    function _harvestStakingReward(address certToken) internal {
        uint vID = vaultManager.vaultId(certToken, 0);
        address caller = _msgSender();
        vaultManager.claimReward(vID, caller);
        vaultManager.claimReward(vID + 1, caller);
        vaultManager.claimReward(vID + 2, caller);
    }

    function upgradeVault(address certToken) external {
        _upgradeVault(IDABotCertToken(certToken), _msgSender());
    }

    function _createVaults(address certToken) private {
        IERC20 asset = IERC20(IDABotCertToken(certToken).asset());
        uint vID0 = vaultManager.createVault(VaultData(certToken, asset, address(this), 0, WARMUP_VAULT));
        vaultManager.createVault(VaultData(certToken, asset, address(this), 1, REGULAR_VAULT));
        uint vID2 = vaultManager.createVault(VaultData(certToken, asset, address(this), 2, VIP_VAULT));

        vaultManager.setVaultOption(vID0, abi.encode(RegularVaultOption(true))); 
        vaultManager.setVaultOption(vID2, abi.encode(RegularVaultOption(true))); 
    }

    function _upgradeVault(IDABotCertToken certToken, address account) private {
        require(certToken.owner() == address(this), Errors.BSTMOD_INVALID_CERTIFICATE_ASSET);
        uint vID0 = vaultManager.vaultId(address(certToken), 0);
        uint amount = vaultManager.balanceOf(vID0, account);
        if (amount == 0)
            return;
        vaultManager.delegateWithdraw(vID0, account, amount);
        vaultManager.delegateDeposit(vID0 + 1, account, account, amount, 0);
    }

    /**
    @dev Removes an asset from the bot's porfolio. 

    It requires that none is currently staking to this asset. Otherwise, the transaction fails.
     */
    function removePortfolioAsset(IRoboFiERC20 asset) public onlyBotOwner {
        BotStakingData storage ds = DABotStakingLib.staking();
        address certToken = ds.portfolio[asset].certToken;
        _destroyVaults(certToken);
        ds.removePortfolioAsset(asset);
        emit AssetRemoved(address(asset), certToken);
    }

    function _destroyVaults(address certToken) internal {
        uint vID = vaultManager.vaultId(certToken, 0);
        vaultManager.destroyVault(vID);
        vaultManager.destroyVault(vID + 1);
        vaultManager.destroyVault(vID + 2);
    }

    /**
    @dev Retrieves the max stakable amount for the specified asset.

    During IBO, the max stakable amount is bound by the {portfolio[asset].iboCap}.
    After IBO, it is limited by {portfolio[asset].cap}.
     */
    function getMaxStake(IRoboFiERC20 asset) public view returns(uint) {
        BotSetting storage setting = DABotSettingLib.setting();
        BotStakingData storage staking = DABotStakingLib.staking();

        if (block.timestamp < setting.iboStartTime())
            return 0;

        PortfolioAsset storage pAsset = staking.portfolio[asset];

        uint totalStake = IDABotCertToken(pAsset.certToken).totalStake();

        if (block.timestamp < setting.iboEndTime())
            return pAsset.iboCap - totalStake;

        return pAsset.cap - totalStake;
    }

    /**
    @dev Stakes an mount of crypto asset to the bot and get back the certificate token.

    The staking function is only valid after the IBO starts and on ward. Before that calling 
    to this function will be failt.

    When users stake during IBO time, users will immediately get the certificate token. After the
    IBO time, certificate token will be issued after a [warm-up] period.
     */
    function stake(IRoboFiERC20 asset, uint amount) 
        external 
        virtual 
        activeBot 
        whitelistCheck(_msgSender(), WHITELIST_CHECK_STAKE_USERS) 
    {
        if (amount == 0) return;

        BotStakingData storage ds = DABotStakingLib.staking();
        BotSetting storage setting = DABotSettingLib.setting();
        PortfolioAsset storage pAsset = ds.portfolio[asset];

        require(setting.iboStartTime() <= block.timestamp, Errors.BSTMOD_PRE_IBO_REQUIRED);
        require(address(asset) != address(0), Errors.BSTMOD_INVALID_PORTFOLIO_ASSET);
        require(pAsset.certToken != address(0), Errors.BSTMOD_INVALID_CERTIFICATE_ASSET);

        uint maxStakeAmount = getMaxStake(asset);
        require(maxStakeAmount > 0, Errors.BSTMOD_PORTFOLIO_FULL);

        uint stakeAmount = amount > maxStakeAmount ? maxStakeAmount : amount;
        _mintCertificate(asset, pAsset, stakeAmount);        
    }

    /**
    @dev Redeems an amount of certificate token to get back the original asset.

    All unstake requests are denied before ending of IBO.
     */
    function unstake(IDABotCertToken certToken, uint amount) external virtual {
        if (amount == 0) return;
        BotSetting storage setting = DABotSettingLib.setting();
        IERC20 asset = certToken.asset();
        require(address(asset) != address(0), Errors.BSTMOD_INVALID_CERTIFICATE_ASSET);
        require(setting.iboEndTime() <= block.timestamp, Errors.BSTMOD_AFTER_IBO_REQUIRED);
        require(certToken.balanceOf(_msgSender()) >= amount, Errors.BSTMOD_INSUFFICIENT_FUND);

        _unstake(_msgSender(), certToken, amount);
    }

    function _mintCertificate(IERC20 asset, PortfolioAsset storage pAsset, uint amount) internal {
        BotSetting storage setting = DABotSettingLib.setting();
        IDABotCertToken token = IDABotCertToken(pAsset.certToken);
        BotStatus status = setting.status();
        
        asset.safeTransferFrom(_msgSender(), address(token), amount);
        uint certTokenAmount = token.mint(address(vaultManager), amount); 

        uint vID = vaultManager.vaultId(pAsset.certToken, 0);
        if (status == BotStatus.IN_IBO) {
            vaultManager.delegateDeposit(vID + 2 /* VIP Vault */, address(0), _msgSender(), amount, 0);
        } else {
            uint64 duration = uint64(setting.warmupTime() * setting.getStakingTimeMultiplier());
            vaultManager.delegateDeposit(vID + (duration == 0 ? 1 : 0), address(0), _msgSender(), certTokenAmount, duration);
        }

        emit Stake(address(asset), amount, address(pAsset.certToken), certTokenAmount, address(0));
    }

    function _unstake(address account, IDABotCertToken certToken, uint amount) internal virtual {
        BotSetting storage setting = DABotSettingLib.setting();
        uint duration = setting.cooldownTime() * setting.getStakingTimeMultiplier(); 
        address asset = address(certToken.asset()); 
        uint assetAmount = certToken.value(amount);

        if (duration == 0) {
            certToken.burn(_msgSender(), amount);
            emit Unstake(address(certToken), amount, asset, assetAmount, address(0), block.timestamp);
            return;
        }

        BotMetaData storage meta = DABotMetaLib.metadata();
        BotStakingData storage ds = DABotStakingLib.staking();

        address locker = meta.deployLocker(BOT_CERT_TOKEN_COOLDOWN_HANDLER_ID,
                LockerData(address(this), 
                _msgSender(), 
                address(certToken), 
                uint64(block.timestamp), 
                uint64(block.timestamp + duration))
            );

        ds.cooldown[account].push(IDABotCertLocker(locker));
        ds.lockers[locker] = true;
        certToken.transferFrom(account, locker, amount);

        emit Unstake(address(certToken), amount, asset, assetAmount, locker, block.timestamp + duration);
    }

    function stakeBalanceOf(address account, IRoboFiERC20 asset) external view returns(uint) {
        return DABotStakingLib.staking().stakeBalanceOf(account, asset);
    }

    function warmupBalanceOf(address account, IRoboFiERC20 asset) external view returns(uint) {
        return DABotStakingLib.staking().warmupBalanceOf(account, asset);
    }

    function cooldownBalanceOf(address account, IDABotCertToken certToken) external view returns(uint) {
        return DABotStakingLib.staking().cooldownBalanceOf(account, certToken);
    }

    function certificateOf(IRoboFiERC20 asset) external view returns(IDABotCertToken) {
        return DABotStakingLib.staking().certificateOf(asset);
    }

    function assetOf(address certToken) external view returns(IERC20) {
        return IDABotCertToken(certToken).asset();
    }

    function isCertLocker(address account) external view returns(bool) {
        return DABotStakingLib.staking().lockers[account];
    }

    /**
    @dev Gets detail information of warming-up certificate tokens (for all staked assets).
    */
    function warmupDetails(address account) public view returns(LockerInfo[] memory) {
        BotStakingData storage ds = DABotStakingLib.staking();
        IDABotCertLocker[] storage lockers = ds.warmup[account];
        return _lockerInfo(lockers);
    }

    /**
    @dev Gets detail information of cool-down requests (for all certificate tokens)
     */
    function cooldownDetails(address account) public view returns(LockerInfo[] memory) {
        BotStakingData storage ds = DABotStakingLib.staking();
        IDABotCertLocker[] storage lockers = ds.cooldown[account];
         return _lockerInfo(lockers);
    }

    function _lockerInfo(IDABotCertLocker[] storage lockers) internal view returns(LockerInfo[] memory result) {
        result = new LockerInfo[](lockers.length);
        for (uint i = 0; i < lockers.length; i++) {
            result[i] = lockers[i].detail();
        }
    }

    /**
    @dev Itegrates all lockers of the caller, and try to unlock these lockers if time condition meets.
        The unlocked lockers will be removed from the global `_warmup`.

        The function will return when one of the below conditions meet:
        (1) 20 lockers has been unlocked,
        (2) All lockers have been checked
     */
    function releaseWarmups() public {
        _releaseLockers(DABotStakingLib.staking(), _msgSender(), false);
    }

    function releaseCooldowns() public {
        _releaseLockers(DABotStakingLib.staking(), _msgSender(), true);
    }

    function _releaseLockers(BotStakingData storage ds, address account, bool isCooldown) internal {
        IDABotCertLocker[] storage lockers = isCooldown ? ds.cooldown[account] : ds.warmup[account];
        uint max = lockers.length < 20 ? lockers.length : 20;
        uint idx = 0;
        for (uint count = 0; count < max && idx < lockers.length;) {
            IDABotCertLocker locker = lockers[idx];
            (bool unlocked,) = locker.tryUnlock(); 
            if (!unlocked) {
                idx++;
                continue;
            }
            // if (isCooldown)
            //     IERC20(locker.asset()).safeTransfer(account, amount);
            ds.lockers[address(locker)] = false;
            locker.finalize(); 
            lockers[idx] = lockers[lockers.length - 1];
            lockers.pop();
            count++;
        }
    }
}