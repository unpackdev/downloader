// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "./console.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

import "./IDebtor.sol";
import "./ICreditor.sol";
import "./ISwap.sol";
import "./ISelfCompoundingYield.sol";
import "./ITimelockRegistryUpgradeable.sol";
import "./IStakingMultiRewards.sol";
import "./StorageV1ConsumerUpgradeable.sol";

/**
    Vault is a baseAsset lender.
    Vehicles are borrowers that put money to work.

    The design logic of the system:
        Each vault and vehicle is treated as an independent entity.
        Vault is willing to lend money, but with limited trust on the vehicles
        Vehicles is willing to borrow money, but only when it is beneficial to how it is using.

        Vehicle can potentially borrow from multiple vaults.

        Its sole purpose being making money to repay debt and share profits to all stakeholders.

        The vault focuses on:

        1) Deciding where the money should be lended to.

        2) Liquidating the returned baseAsset to longAsset.

*/
contract VaultUpgradeable is StorageV1ConsumerUpgradeable, ERC20Upgradeable, ICreditor {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event Deposit(address indexed _who, uint256 _amount);
    event Withdraw(address indexed _who, uint256 _amount);
    event Longed(uint256 totalDeposit, uint256 baseProfit, uint256 longedProfit);
    event WithdrawFeeUpdated(uint256 _withdrawFeeRatio, uint256 _withdrawalFeeHalfDecayPeriod, uint256 _withdrawalFeeWaivedPeriod);

    // Vault lends, vehicle borrows
    //      governance/admin to decide the maximum funds that could be invested
    //      in an IV. 
    //      Operator push and pull the funds arbitrarily within these boundaries. 
    //      That makes it easier to decentralize Operator. 
    struct VehicleInfo {
        // Debt related
        uint256 baseAssetDebt; // the amount of baseAsset that was borrowed by the vehicle
        // how much the vault is willing to lend
        bool disableBorrow; // if the vehicle can continue to borrow assets
        uint256 lendMaxBps; // the vault is willing to lend `min(lendRatioNum * totalBaseAsset,  borrowCap)`
        uint256 lendCap; // the maximum amount that the vault is willing to lend to the vehicle
    }

    // users deposit baseAsset
    // the accrued interest is returned with longAsset
    address public baseAsset;
    address public longAsset;

    // if `selfCompoundingLongAsset` is address(0), 
    // then it is not self compounding, we distribute long asset to the pool as it is
    address public selfCompoundingLongAsset;

    // vehicle
    mapping (address => VehicleInfo) public vInfo;

    // We disable deposit and withdraw in the same block by default to prevent attacks
    // However, we could allow it after the external protocol behaviour has been verified
    mapping(address => bool) public flashDepositAndWithdrawAllowed;
    mapping(address => uint256) public lastActivityBlock;

    // By default, there is a withdrawal fee applied on users
    // This flag allows us to exempt withdrawal fees on certain addresses
    // This is useful for protocol collaboration
    mapping(address => bool) public noWithdrawalFee;
    mapping(address => uint256) public lastFeeTime;

    // An artificial cap for experimental vaults
    uint256 public depositCap;

    // flag that determines if there's withdrawal fee

    mapping(address => uint256) public withdrawalFeeOccured;
    
    uint256 public withdrawFeeRatio; // Disable withdrawFee for newly deposted asset if it is set to 0.
    uint256 public withdrawalFeeHalfDecayPeriod; // Disable withdrawFee while withdrawing if it is set to 0.
    uint256 public withdrawalFeeWaivedPeriod;

    // Unit of the withdrawl fee ratio and the lending cap.
    uint256 constant BPS_UNIT = 10000;

    // Our withdrawal fee will decay 1/2 for every decay period
    // e.g. if decay period is 2 weeks, the maximum wtihdrawal fee after two weeks is 0.5%
    //      after 4 weeks: 0.25%.
    
    // Maximum cap of allowed withdrawl fee. [Unit: BPS_UNIT]
    uint256 constant WITHDRAWAL_FEE_RATIO_CAP = 100; // 1% max

    // Investment vehicles that generates the interest
    EnumerableSetUpgradeable.AddressSet investmentVehicles;

    /// True if deposit is enabled.
    bool public vaultDepositEnabled;

    // Address of the reward pool (StakingMultiRewardsUpgradable)
    address rewardPool;

    modifier ifVaultDepositEnabled() {
        require(vaultDepositEnabled, "Vault: Deposit not enabled");
        require(totalSupply() <= depositCap, "Vault: Deposit cap reached");
        _;
    }

    modifier onlyDebtor() {
        require(isDebtor(msg.sender), "Vault: caller is not a debtor");
        _;
    }

    modifier flashDepositAndWithdrawDefence() {
        if(!flashDepositAndWithdrawAllowed[msg.sender]){
            require(lastActivityBlock[msg.sender] != block.number, "Vault: flash forbidden");
        }
        lastActivityBlock[msg.sender] = block.number;
            
        _;
    }

    modifier timelockPassed(address iv) {
        // if timelock registry is not set, then timelock is not yet activated.
        if(registry() != address(0)) { 
            // Check the timelock if it has been enabled.
            // This is present to ease initial vault deployment and setup, once a vault has been setup and linked properly 
            // with the IVs, then we could proceed and enable the timelock. 
            if(ITimelockRegistryUpgradeable(registry()).vaultTimelockEnabled(address(this))) {
                require(ITimelockRegistryUpgradeable(registry()).isIVActiveForVault(address(this), iv), "Vault: IV not available yet");
            }
        } 
        _;
    }

    /// Checks if the target address is debtor
    /// @param _target target address
    /// @return true if target address is debtor, false if not
    function isDebtor(address _target) public view returns(bool) {
        return investmentVehicles.contains(_target);
    }

    /// Initializes the contract
    function initialize(
        address _store,
        address _baseAsset,
        address _longAsset,
        uint256 _depositCap
    ) public virtual initializer {
        require(_baseAsset != _longAsset, "Base asset cannot be the same as long asset");
        super.initialize(_store);
        baseAsset = _baseAsset;
        longAsset = _longAsset;
        depositCap = _depositCap;
        vaultDepositEnabled = true;
        // All vaults have 0 withdraw fee in the beginning.
        // to facilitate kickstarting the vault
        _setWihdrawFeeParameter(0, 2 weeks, 6 weeks);
        
        __ERC20_init(
            string(abi.encodePacked("lVault: ", ERC20Upgradeable(_baseAsset).name(), "=>", ERC20Upgradeable(_longAsset).name())),
            string(abi.encodePacked("long_", ERC20Upgradeable(_baseAsset).symbol(), "_", ERC20Upgradeable(_longAsset).symbol()))
        );
    }

    /// Set the reward pool for distributing the longAsset.
    ///
    /// See Also: StakingMultiRewardsUpgradable
    /// @param _rewardPool Address of the reward pool.
    function setRewardPool(address _rewardPool) public adminPriviledged {
        rewardPool = _rewardPool;
    }

    // Deposit triggers investment when the investment ratio is under some threshold
    /// Deposit baseAsset into the vault
    /// @param amount The amount of baseAsset deposited from the user
    function deposit(uint256 amount) public virtual {
        _deposit(msg.sender, msg.sender, amount);
    }

    /// Deposit baseAsset into the vault for targetAccount.
    /// @param targetAccount Target account to deposit for
    /// @param amount The amount of baseAsset deposited from the user
    function depositFor(address targetAccount, uint256 amount)
        public virtual
    {
        _deposit(msg.sender, targetAccount, amount);
    }

    function _deposit(address assetFrom, address shareTo, uint256 amount)
        internal virtual
        ifVaultDepositEnabled
        flashDepositAndWithdrawDefence
    {
        emit Deposit(shareTo, amount);
        IERC20Upgradeable(baseAsset).safeTransferFrom(
            assetFrom,
            address(this),
            amount
        );
        // Any deposits would reset the deposit time to the newest
        
        _mint(shareTo, amount);
        _accountWithdrawFeeAtDeposit(shareTo, amount);
    }

    function _accountWithdrawFeeAtDeposit(address _who, uint256 _amount) internal {
        if(!noWithdrawalFee[_who] && withdrawFeeRatio > 0) {
            uint256 withdrawFeeNewlyOccured = _amount.mul(withdrawFeeRatio).div(BPS_UNIT);
            withdrawalFeeOccured[_who] = withdrawlFeePending(_who).add(withdrawFeeNewlyOccured);
            lastFeeTime[msg.sender] = block.timestamp;
        }
    }
    /// Withdraw the baseAsset from the vault.
    /// Always withdraws 1:1, then distributes withdrawal fee
    /// because the interest has already been paid in other forms.
    /// The actual amount of the baseAsset user received is subjet to the pending withdraw fee.
    /// @param amount Amount of the baseAsset to be withdrawed from the vault.
    function withdraw(uint256 amount) public virtual flashDepositAndWithdrawDefence {
        // The withdrawal starts from the first investmentVehicle
        // This implies that we have the concept of investment depth:
        // The more profitable ones are the ones with higher priority
        // and would keep them deeper in the stack (`i` larger means deeper)
        // There MUST be at least one investmentVehicle, thus it is ok not to use SafeMath here        
        uint256 balance = IERC20Upgradeable(address(this)).balanceOf(msg.sender);
        require(balance >= amount, "msg.sender doesn't have that much balance.");

        uint256 baseAssetBalanceInVault = IERC20Upgradeable(baseAsset).balanceOf(address(this));

        if (investmentVehicles.length() > 0) {
            for (
                uint256 i = 0; // withdraw starts from the first vehicle
                i < investmentVehicles.length() && baseAssetBalanceInVault < amount; // until it reaches the end, or if we got enough
                i++
            ) {
                _withdrawFromIV(investmentVehicles.at(i), amount - baseAssetBalanceInVault);

                // Update `baseAssetBalanceInVault`
                baseAssetBalanceInVault = IERC20Upgradeable(baseAsset).balanceOf(address(this));
            }
        }

        uint256 sendAmount = MathUpgradeable.min(amount, baseAssetBalanceInVault);
        _withdrawSendwithFee(msg.sender, sendAmount);
        emit Withdraw(msg.sender, sendAmount);

        _burn(msg.sender, sendAmount);
    }

    function _withdrawSendwithFee(address _who, uint256 _sendAmount) internal {
        uint256 _balance = IERC20Upgradeable(address(this)).balanceOf(msg.sender);
        uint256 _withdrawalFeePending = withdrawlFeePending(_who);
        
        uint256 sendAmountActual = _sendAmount;
        if(_withdrawalFeePending > 0)
        {
            uint256 withdrawFee = _withdrawalFeePending.mul(_sendAmount).div(_balance);
            withdrawalFeeOccured[_who] = _withdrawalFeePending.sub(withdrawFee);
            lastFeeTime[msg.sender] = block.timestamp;
            sendAmountActual = _sendAmount.sub(withdrawFee);
            IERC20Upgradeable(address(baseAsset)).safeTransfer(treasury(), withdrawFee);
        }
        IERC20Upgradeable(address(baseAsset)).safeTransfer(_who, sendAmountActual);
    }

    /// Withdral all the baseAsset from an IV.
    /// @param _iv Address of the IV.
    function withdrawAllFromIV(address _iv) public opsPriviledged {
        _withdrawFromIV(_iv, baseAssetDebtOf(_iv));
    }

    /// Withdral ceterain amount of the baseAsset from an IV.
    /// @param _iv Address of the IV.
    /// @param _amount Amount of the baseAsset to be withdrawed.
    function withdrawFromIV(address _iv, uint256 _amount) public opsPriviledged {
        _withdrawFromIV(_iv, _amount);
    }

    /// Withdral ceterain amount of the baseAsset from multiple IVs.
    /// See withdrawFromIV for details.
    function withdrawFromIVs(address[] memory _ivs, uint256[] memory _amounts) public opsPriviledged {
        for(uint256 i = 0; i < _ivs.length; i++) {
            _withdrawFromIV(_ivs[i], _amounts[i]);
        }
    }

    /// Withdral all the baseAsset from multiple IVs.
    /// See withdrawAllFromIV for details.
    function withdrawAllFromIVs(address[] memory _ivs) public opsPriviledged {
        for(uint256 i = 0; i < _ivs.length; i++) {
            _withdrawFromIV(_ivs[i], baseAssetDebtOf(_ivs[i]));
        }
    }

    function _withdrawFromIV(address iv, uint256 amount) internal {
        uint256 beforeWithdraw = IERC20Upgradeable(baseAsset).balanceOf(address(this));
        // request amount
        IDebtor(iv).withdrawAsCreditor(
            amount
        );
        // refresh balance In Vault
        uint256 afterWithdraw = IERC20Upgradeable(baseAsset).balanceOf(address(this));
        uint256 actuallyWithdrawn = afterWithdraw.sub(beforeWithdraw);

        _accountingDebtRepayment(iv, actuallyWithdrawn);
    }

    function _accountingDebtRepayment(address _debtor, uint256 repaymentAmountInBase) internal {
        if(repaymentAmountInBase <= vInfo[_debtor].baseAssetDebt){
            vInfo[_debtor].baseAssetDebt = (vInfo[_debtor].baseAssetDebt).sub(repaymentAmountInBase);
        } else {
            // this handles the anomaly case where we got more repayment than the debt.
            vInfo[_debtor].baseAssetDebt = 0;
        }
    }

    function _accountingFundsLendingOut(address _debtor, uint256 _fundsSentOutInBase) internal {
        vInfo[_debtor].baseAssetDebt = (vInfo[_debtor].baseAssetDebt).add(_fundsSentOutInBase);
    }


    /// Invest all the available baseAsset in the vault.
    function investAll() public opsPriviledged {
        // V1 only invests into the default vehicle `investmentVehicles[0]`

        // Vault only pushes funds into the vehicle
        // but the money is not really at work, real investment has to
        // happen under the hood
        uint256 allAmount = IERC20Upgradeable(address(baseAsset)).balanceOf(address(this));

        _investTo(investmentVehicles.at(0), allAmount);
    }

    /// Invest certain amount of the baseAsset in the vault to an IV.
    /// @param _target Address of the IV.
    /// @param _amount Amount of the baseAsset to be invested.
    function investTo(address _target, uint256 _amount) public opsPriviledged {
        _investTo(_target, _amount);
    }

    /// Invest certain amount of the baseAsset in the vault to multiple IVs.
    function investToIVs(address[] memory _targets, uint256[] memory _amounts) public opsPriviledged {
        for(uint256 i = 0 ; i < _targets.length; i++) {
            _investTo(_targets[i], _amounts[i]);
        }
    }

    /// Migrate certain amount of the baseAsset from one IV to another.
    /// @param _fromIv Address of the source IV.
    /// @param _toIv Address of the destination IV.
    /// @param _pullAmount Amount of the baseAsset to be pulled out from old IV.
    /// @param _pushAmount Amount of the baseAsset to be pushed into the new IV.
    function migrateFunds(address _fromIv, address _toIv, uint256 _pullAmount, uint256 _pushAmount) public opsPriviledged {
        _withdrawFromIV(_fromIv, _pullAmount);
        _investTo(_toIv, _pushAmount);
    }

    /// Calculate the lending capacity of an IV.
    /// This vault cannot lend baseAsset with amount more than the lending capacity.
    /// @param _target Address of the IV.
    /// @return Return the lending capacity. (Unit: BPS_UNIT)
    function effectiveLendCapacity(address _target) public view returns (uint256) {
        // totalSupply is the amount of baseAsset the vault holds
        uint256 capByRatio = totalSupply().mul(vInfo[_target].lendMaxBps).div(BPS_UNIT);

        return MathUpgradeable.min(
            vInfo[_target].lendCap, // hard cap
            capByRatio
        );
    }

    function _investTo(address _target, uint256 _maxAmountBase) internal virtual returns(uint256){
        require(isDebtor(_target), "Vault: investment vehicle not registered");
        
        // The maximum amount that we will attempt to lend out will be the min of
        // the provided argument and the effective lend cap
        _maxAmountBase = MathUpgradeable.min(effectiveLendCapacity(_target), _maxAmountBase);

        IERC20Upgradeable(address(baseAsset)).safeApprove(_target, 0);
        IERC20Upgradeable(address(baseAsset)).safeApprove(_target, _maxAmountBase);
        uint256 baseBefore = IERC20Upgradeable(address(baseAsset)).balanceOf(address(this));

        uint256 reportInvested = IDebtor(address(_target)).askToInvestAsCreditor(
            _maxAmountBase
        );

        uint256 baseAfter = IERC20Upgradeable(address(baseAsset)).balanceOf(address(this));
        uint256 actualInvested = baseBefore.sub(baseAfter);
        require(actualInvested == reportInvested, "Vault: report invested != actual invested");
        
        IERC20Upgradeable(address(baseAsset)).safeApprove(_target, 0);
        _accountingFundsLendingOut(_target, actualInvested);
        return actualInvested;
    }


    /// Add an investment vehicle.
    /// @param newVehicle Address of the new IV.
    /// @param _lendMaxBps Lending capacity of the IV in ratio.
    /// @param _lendCap Lending capacity of the IV.
    function addInvestmentVehicle(
        address newVehicle,
        uint256 _lendMaxBps,
        uint256 _lendCap
    ) public adminPriviledged timelockPassed(newVehicle) returns(uint256) {

        require(!isDebtor(newVehicle),
                "vehicle already registered");
        
        vInfo[newVehicle] = VehicleInfo({
            baseAssetDebt: 0,
            disableBorrow: false, // borrow is enabled by default
            lendMaxBps: _lendMaxBps,
            lendCap: _lendCap
        });

        investmentVehicles.add(newVehicle);
    }

    /// This moves an IV to the lowest withdraw priority.
    /// @param iv Address of the IV.
    function moveInvestmentVehicleToLowestPriority(
        address iv
    ) external adminPriviledged {
        require(isDebtor(iv));

        // This is done by removing iv from the list and re-adding it back.
        // After that, the iv will be at the end of the list.
        investmentVehicles.remove(iv);
        investmentVehicles.add(iv);
    }

    /// Remove an IV from the vault.
    /// @param _target Address of the IV.
    function removeInvestmentVehicle(address _target) public adminPriviledged {
        require(vInfo[_target].baseAssetDebt == 0, "cannot remove vehicle with nonZero debt");
        investmentVehicles.remove(_target);
    }

    /// @return Return the number of the IVs added to this vault.
    function investmentVehiclesLength() public view returns(uint256) {
        return investmentVehicles.length();
    }

    /// @param idx Index of the IV.
    /// @return Return the address of an IV.
    function getInvestmentVehicle(uint256 idx) public view returns(address) {
        return investmentVehicles.at(idx);
    }

    /// @param _iv Address of the IV.
    /// @return Return the debt (in baseAsset) of an IV 
    function baseAssetDebtOf(address _iv) public view returns(uint256) {
        return vInfo[_iv].baseAssetDebt;
    }

    /// Collect the interest from IVs and convert them into longAsset.
    /// The converted longAsset would be distribute to user through the reward pool.
    ///
    /// See also: StakingMultiRewardsUpgradeable
    /// @param ivs List of IVs to collect interest from.
    /// @param minimumLongProfit The minimum LongProfit collected.
    function collectAndLong(address[] memory ivs, uint256 minimumLongProfit) public opsPriviledged virtual {
        uint256 beforeBaseBalance = IERC20Upgradeable(baseAsset).balanceOf(address(this));
        for(uint256 i = 0; i < ivs.length; i++){
            address iv = ivs[i];
            IDebtor(iv).withdrawAsCreditor( interestPendingInIV(iv) );
        }
        uint256 afterBaseBalance = IERC20Upgradeable(baseAsset).balanceOf(address(this));
        uint256 baseProfit = afterBaseBalance.sub(beforeBaseBalance);

        IERC20Upgradeable(baseAsset).safeApprove(swapCenter(), 0);
        IERC20Upgradeable(baseAsset).safeApprove(swapCenter(), baseProfit);
        uint256 longedProfit = ISwap(swapCenter()).swapExactTokenIn(baseAsset, longAsset, baseProfit, minimumLongProfit);
        emit Longed(totalSupply(), baseProfit, longedProfit);
        _distributeProfit(longedProfit);
    }

    function _distributeProfit(uint256 longedProfit) internal {
        if(selfCompoundingLongAsset == address(0)){ // not wrapping, directly notify the reward pool
            IERC20Upgradeable(longAsset).safeTransfer(rewardPool, longedProfit);
            IStakingMultiRewards(rewardPool).notifyTargetRewardAmount(longAsset, longedProfit);
        } else { 
            // we should wrap long asset to self compounding
            IERC20Upgradeable(longAsset).safeApprove(selfCompoundingLongAsset, 0);
            IERC20Upgradeable(longAsset).safeApprove(selfCompoundingLongAsset, longedProfit);
            ISelfCompoundingYield(selfCompoundingLongAsset).deposit(longedProfit);
            uint256 wrappedLongBalance = ERC20Upgradeable(selfCompoundingLongAsset).balanceOf(address(this));

            // notify the wrapped long to the pool
            IERC20Upgradeable(selfCompoundingLongAsset).safeTransfer(rewardPool, wrappedLongBalance);
            IStakingMultiRewards(rewardPool).notifyTargetRewardAmount(selfCompoundingLongAsset, wrappedLongBalance);
        }
    }

    /// Return the intest (profit) of the vault in an IV.
    /// The interest is defined as the baseAsset balance of the vault 
    /// in IV minus the debt that the IV owed the vault.
    /// @param iv The address of the IV.
    /// @return The interest of the vault in the IV.
    function interestPendingInIV(address iv) public view returns(uint256) {
        uint256 balance = IDebtor(iv).baseAssetBalanceOf(address(this));
        uint256 debt = vInfo[iv].baseAssetDebt;
        if(balance > debt) {
            return balance - debt; // No overflow problem.
        } else {
            return 0;
        }
    }

    function _updateRewards(address targetAddr) internal {
        require(rewardPool != address(0), "Reward pool needs to be set.");
        IStakingMultiRewards(rewardPool).updateAllRewards(targetAddr);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        _updateRewards(sender);
        _updateRewards(recipient);
        super._transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        _updateRewards(account);
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        _updateRewards(account);
        super._burn(account, amount);
    }

    /// Set the deposit cap.
    /// @param _depositCap Deposit cap (in baseAsset) of the vault. 
    function setDepositCap(uint256 _depositCap) public adminPriviledged {
        depositCap = _depositCap;
    }

    /// Set the deposit enabled flag.
    /// @param _flag True if the deposit is enabled.
    function setDepositEnabled(bool _flag) public adminPriviledged {
        vaultDepositEnabled = _flag;
    }

    function setFlashDepositAndWithdrawAllowed(address[] memory _targets, bool _flag) public adminPriviledged {
        for(uint256 i = 0 ; i < _targets.length; i++){
            flashDepositAndWithdrawAllowed[_targets[i]] = _flag;
        }
    }

    /// Add accounts to the no-withdrawl fee white list.
    function setNoWithdrawalFee(address[] memory _targets, bool _flag) public adminPriviledged {
        for(uint256 i = 0 ; i < _targets.length ; i++) {
            noWithdrawalFee[_targets[i]] = _flag;
        }
    }

    /// Set the withdraw fee parametrs.
    /// See the withdraw fee documentation for more details
    /// @param _withdrawFeeRatio The withdraw fee ratio. Unit: BPS_UNIT
    /// @param _withdrawalFeeHalfDecayPeriod The half-decay period of the withdraw fee. [second]
    /// @param _withdrawalFeeWaivedPeriod The withdraw fee waived period. [second]
    function setWihdrawFeeParameter(
        uint256 _withdrawFeeRatio,
        uint256 _withdrawalFeeHalfDecayPeriod,
        uint256 _withdrawalFeeWaivedPeriod
    ) external adminPriviledged {
        _setWihdrawFeeParameter(_withdrawFeeRatio, _withdrawalFeeHalfDecayPeriod, _withdrawalFeeWaivedPeriod);
    }

    function _setWihdrawFeeParameter(
        uint256 _withdrawFeeRatio,
        uint256 _withdrawalFeeHalfDecayPeriod,
        uint256 _withdrawalFeeWaivedPeriod
    ) internal {
        require(_withdrawFeeRatio <= WITHDRAWAL_FEE_RATIO_CAP, "withdrawFeeRatio too large");
        withdrawFeeRatio = _withdrawFeeRatio;
        withdrawalFeeHalfDecayPeriod = _withdrawalFeeHalfDecayPeriod;
        withdrawalFeeWaivedPeriod = _withdrawalFeeWaivedPeriod;
        emit WithdrawFeeUpdated(_withdrawFeeRatio, _withdrawalFeeHalfDecayPeriod, _withdrawalFeeWaivedPeriod);
    }

    /// Calculate the current unsettled withdraw fee.
    /// @param _who The address to calculate the fee.
    /// @return fee Return the amount of the withdraw fee (as baseAsset). 
    function withdrawlFeePending(address _who) public view returns (uint256 fee) {
        if(noWithdrawalFee[_who]  || withdrawalFeeHalfDecayPeriod == 0){
            return 0;
        } else {
            uint256 timePassed = block.timestamp.sub(lastFeeTime[_who]);
            if(timePassed > withdrawalFeeWaivedPeriod) {
                return 0;
            } else {
                // No need for safe math here.
                return withdrawalFeeOccured[_who] >> (timePassed/withdrawalFeeHalfDecayPeriod);
            }
        }           
    }

    /// Set the self-compounding vault for the long asset.
    ///
    /// See also: SelfCompoundingYieldUpgradable
    /// @param _selfCompoundingLong Address of the self-compounding vault.
    function setLongSelfCompounding(address _selfCompoundingLong) public adminPriviledged {
        selfCompoundingLongAsset = _selfCompoundingLong;
    }

}
