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
import "./ITimelockRegistryUpgradeable.sol";
import "./IStakingMultiRewards.sol";
import "./StorageV1ConsumerUpgradeable.sol";

/**
    SelfCompoundingYieldUpgradeable is a special type of vault where only whitelisted addresses 
    can deposit. It also works with a share price instead of a 1:1 ratio. 
*/
contract SelfCompoundingYieldUpgradeable is StorageV1ConsumerUpgradeable, ERC20Upgradeable, ICreditor {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event Deposit(address indexed _who, uint256 _amount);
    event Withdraw(address indexed _who, uint256 _amount);

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
    /// Address of the base asset.
    address public baseAsset;

    // vehicle
    mapping (address => VehicleInfo) public vInfo;

    /// Unit of the lending cap.
    uint256 public constant BPS_UNIT = 10000;
    /// Unit of the share price.
    uint256 constant public SHARE_UNIT = 1e18;

    // Investment vehicles that generates the interest
    EnumerableSetUpgradeable.AddressSet investmentVehicles;
    EnumerableSetUpgradeable.AddressSet whitelistDeposit;

    modifier onlyWhitelistDeposit() {
      require(whitelistDeposit.contains(msg.sender), "Not whitelist deposit");
      _;
    }

    modifier onlyDebtor() {
        require(isDebtor(msg.sender), "Vault: caller is not a debtor");
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
        address _baseAsset
    ) public virtual initializer {
        super.initialize(_store);
        baseAsset = _baseAsset;
    }

    // Deposit triggers investment when the investment ratio is under some threshold
    /// Deposit baseAsset into the vault
    /// @param baseAmount The amount of baseAsset deposited from the user
    function deposit(uint256 baseAmount) public virtual {
        _deposit(msg.sender, msg.sender, baseAmount);
    }

    /// Deposit baseAsset into the vault for targetAccount.
    /// @param targetAccount Target account to deposit for
    /// @param baseAmount The amount of baseAsset deposited from the user
    function depositFor(address targetAccount, uint256 baseAmount)
        public virtual
    {
        _deposit(msg.sender, targetAccount, baseAmount);
    }

    function _deposit(address assetFrom, address shareTo, uint256 baseAmount)
        internal virtual
        onlyWhitelistDeposit
    {
        emit Deposit(shareTo, baseAmount);
        IERC20Upgradeable(baseAsset).safeTransferFrom(
            assetFrom,
            address(this),
            baseAmount
        );
        // when totalsupply is 0, sharePrice will return SHARE_UNIT
        uint256 shareToMint = baseAssetToShare(baseAmount);

        _mint(shareTo, shareToMint);
    }

    /// Burns the share amount and withdraws respective base asset.
    /// @param shareAmount Amount of the share of the vault.
    function withdraw(uint256 shareAmount) public virtual {
        // The withdrawal starts from the first investmentVehicle
        // This implies that we have the concept of investment depth:
        // The more profitable ones are the ones with higher priority
        // and would keep them deeper in the stack (`i` larger means deeper)
        // There MUST be at least one investmentVehicle, thus it is ok not to use SafeMath here
        uint256 shareBalance = IERC20Upgradeable(address(this)).balanceOf(msg.sender);
        require(shareBalance >= shareAmount, "msg.sender doesn't have that much balance.");

        uint256 baseAmountRequested = shareToBaseAsset(shareAmount); 

        uint256 baseAssetBalanceInVault = IERC20Upgradeable(baseAsset).balanceOf(address(this));

        if (investmentVehicles.length() > 0) {
            for (
                uint256 i = 0; // withdraw starts from the first vehicle
                i < investmentVehicles.length() && baseAssetBalanceInVault < baseAmountRequested; // until it reaches the end, or if we got enough
                i++
            ) {
                _withdrawFromIV(investmentVehicles.at(i), baseAmountRequested - baseAssetBalanceInVault);

                // Update `baseAssetBalanceInVault`
                baseAssetBalanceInVault = IERC20Upgradeable(baseAsset).balanceOf(address(this));
            }
        }

        uint256 sendAmount = MathUpgradeable.min(baseAmountRequested, baseAssetBalanceInVault);
        uint256 shareBurned = baseAssetToShare(sendAmount);

        IERC20Upgradeable(address(baseAsset)).safeTransfer(msg.sender, sendAmount);
        emit Withdraw(msg.sender, sendAmount);
        _burn(msg.sender, shareBurned);
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
        uint256 capByRatio = totalSupply().mul(sharePrice()).div(SHARE_UNIT).mul(vInfo[_target].lendMaxBps).div(BPS_UNIT);

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

    /// Add an account to the deposit whitelist.
    /// Unlike VaultUpgradeable, SelfCompoundingYieldUpgradeable doesn't allow accunts to deposit by default.
    /// @param _newDepositor The account to be added to the white list
    function addWhitelistDeposit(
        address _newDepositor
    ) public adminPriviledged {
        whitelistDeposit.add(_newDepositor);
    }

    /// Remove an account to the deposit whitelist.
    /// @param _newDepositor The account to be removed to the white list
    function removeWhitelistDeposit(
        address _newDepositor
    ) public adminPriviledged {
        whitelistDeposit.remove(_newDepositor);
    }

    /// Check if the target account is in the deposit whitelist
    /// @param _target Target account
    /// @return Return True
    function isWhitelistDeposit(
        address _target
    ) public view returns (bool) {
        return whitelistDeposit.contains(_target);
    }

    /// Add an investment vehicle.
    /// @param newVehicle Address of the new IV.
    /// @param _lendMaxBps Lending capacity of the IV in ratio.
    /// @param _lendCap Lending capacity of the IV in absolute numbers.
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

    /// @return Return the amount of baseAsset that is invested to IVs
    function baseAssetInvested() public view returns (uint256) {
      uint256 totalBaseAssetInvested = 0;

      for (uint256 i = 0; i < investmentVehicles.length(); i++) {
        address iv = investmentVehicles.at(i);
        totalBaseAssetInvested = totalBaseAssetInvested.add(IDebtor(iv).baseAssetBalanceOf(address(this)));
      }      
      return totalBaseAssetInvested;
    }

    /// @return Total amount of baseAsset (invested + not invested) belongs to this vault.
    function totalBaseAsset() public view returns (uint256) {
      return baseAssetInvested().add(IERC20Upgradeable(baseAsset).balanceOf(address(this)));
    }

    /// @return Return the share price. (Unit: SHARE_UNIT) 
    function sharePrice() public view returns (uint256) {
      if(totalSupply() != 0){
        return totalBaseAsset().mul(SHARE_UNIT).div(totalSupply());
      } else {
        return SHARE_UNIT;
      }
    }

    /// Calculate the corrsponding amount of baseAsset
    /// @param share Amount of the vault share.
    /// @return The corrsponding amount of baseAsset.
    function shareToBaseAsset(uint256 share) public view returns (uint256) {
        return share.mul(sharePrice()).div(SHARE_UNIT);
    }

    // Calculate the corrsponding amount of share
    /// @param baseAmount Amount of baseAsset.
    /// @return The corrsponding amount of vault share.
    function baseAssetToShare(uint256 baseAmount) public view returns (uint256) {
        return baseAmount.mul(SHARE_UNIT).div(sharePrice());
    }

}
