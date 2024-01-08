// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "./console.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./StorageV1ConsumerUpgradeable.sol";
import "./IDebtor.sol";
import "./ICreditor.sol";
import "./IInsuranceProvider.sol";

import "./EnumerableSetUpgradeable.sol";

/**
    InvestmentVehicleSingleAssetBaseV1Upgradeable is the base contract for 
    single asset IVs. It will receive only one kind of asset and invest into 
    an investment opportunity. Every once in a while, operators should call the
    `collectProfitAndDistribute` to perform accounting for relevant parties. 

    Apart from the usual governance and operators, there are two roles for an IV: 
    * "creditors" who lend their asset 
    * "beneficiaries" who provide other services. (e.g. insurance, operations, tranches, boosts)
    
    Interest are accrued to their contribution respectively. Creditors gets their interest with respect
    to their lending amount, whereas the governance will set the ratio that is distributed to beneficiaries.
*/
abstract contract InvestmentVehicleSingleAssetBaseV1Upgradeable is
    StorageV1ConsumerUpgradeable, IDebtor
{
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 public constant RATIO_DENOMINATOR = 10000;
    uint256 public constant ASSET_ID_BASE = 0;

    uint256 public constant SHARE_UNIT = 10 ** 18;

    // profit sharing roles (beneficiaries)
    uint256 constant ROLE_OPERATIONS = 0;
    uint256 constant ROLE_INSURER = 1;

    address public baseAsset;

    // shares
    uint256 public totalShares;
    uint256 public sharePrice;
    mapping(address => uint256) public shareBalance;

    struct ProfitShareInfo {
        uint256 ratio;  // only used by PSCAT_PROTOCOL
        uint256 profit; // only used by PSCAT_PROTOCOL
        uint256 role;
    }

    event DividendClaimed(address _who, uint256 amount);
    event BeneficiaryAdded(address _target, uint256 _psRatio, uint256 _psRole);
    event BeneficiaryRemoved(address _target);
    event VaultRemoved(address _target);
    event CreditorWithdrawn(address _creditor, uint256 _baseAssetRequested, uint256 _baseAssetTransferred);
    event CreditorInvested(address _creditor, uint256 _baseAssetInvested, uint256 shareMinted);
    
    event OpsInvestmentPulled(uint256 _amount);
    event OpsInvestAll();
    event OpsCollectProfit(uint256 baseAssetProfit);

    event InsuranceClaimFiled(uint256 filedAmount);
    
    mapping(address => ProfitShareInfo) public psInfo;

    EnumerableSetUpgradeable.AddressSet psList;

    /// Whitelist the vaults/ creditors for depositing funds into the IV.
    mapping(address => bool) public activeCreditor;

    address[] public profitAssets;
    mapping(address => uint256) public profitAssetHeld;

    modifier onlyBeneficiary() {
        require(isBeneficiary(msg.sender) ,"IVSABU: msg.sender is not a beneficiary");
        _;
    }

    modifier onlyCreditor() {
        require(activeCreditor[msg.sender] || msg.sender == treasury() || msg.sender == governance() ,"IVSABU: msg.sender is not a creditor");
        _;
    }

    function initialize(address _store, address _baseAsset) public virtual initializer {
        require(profitAssets.length == 0, "IVSABU: profitToken should be empty");
        super.initialize(_store);
        baseAsset = _baseAsset;
        profitAssets.push(baseAsset);
        // when initializing the strategy, all profit is allocated to the creditors
        require(profitAssets[ASSET_ID_BASE] == baseAsset, "IVSABU: Base asset id should be predefined constant");
        sharePrice = SHARE_UNIT; //set initial sharePrice
    }

    /// Check if a target is a beneficiary (profit share).
    /// @param _address target address
    /// @return Return true if the address is a beneficiary.
    function isBeneficiary(
        address _address
    ) public view returns (bool) {
        return psList.contains(_address);
    }

    /// Add a creditor (typically a vault) to whitelist.
    /// @param _target Address of the creditor.
    function addCreditor(
        address _target
    ) public adminPriviledged
    {
        activeCreditor[_target] = true;
    }

    /// Claim the dividend.
    function claimDividendAsBeneficiary() external returns(uint256) {
        return _claimDividendForBeneficiary(msg.sender);
    }

    /// Claim the dividend for a beneficiary.
    /// @param _who Address of the beneficiary.
    function claimDividendForBeneficiary(address _who) external opsPriviledged returns(uint256) {
        return _claimDividendForBeneficiary(_who);
    }

    function _claimDividendForBeneficiary(address _who) internal returns(uint256) {
        ProfitShareInfo storage info = psInfo[_who];
        uint256 profit = info.profit;

        require(profit > 0, "Must have non-zero dividend.");        
        
        uint256 inVehicleBalance =
            IERC20Upgradeable(baseAsset).balanceOf(address(this));
        
        if (inVehicleBalance < profit) {
            _pullFundsFromInvestment(profit.sub(inVehicleBalance));
            inVehicleBalance = IERC20Upgradeable(baseAsset).balanceOf(address(this));
            profit = MathUpgradeable.min(profit, inVehicleBalance);
        }

        IERC20Upgradeable(baseAsset).safeTransfer(_who, profit);
        info.profit = (info.profit).sub(profit);
        emit DividendClaimed(_who, profit);
        return profit;
    }

    /// Remove the target address from the whitelist for further depositing funds into IV.
    /// The target address can still withdraw the deposited funds.
    /// @param _target Vault address.
    function removeVault(
        address _target
    ) public adminPriviledged
    {
        activeCreditor[_target] = false;
        emit VaultRemoved(_target);
    }

    /// Adds a beneficiary to the Investment Vehicle.
    /// A beneficiary is a party that benefits the Investment Vehicle, thus
    /// should gain something in return.
    /// @param _target Address of the new beneficiary
    /// @param _psRatio Profit sharing ratio designated to the beneficiary
    /// @param _psRole an identifier for different roles in the protocol 
    function addBeneficiary(
        address _target,
        uint256 _psRatio,
        uint256 _psRole
    ) public adminPriviledged {
        require(
            !isBeneficiary(_target),
            "IVSABU: target already is a beneficiary"
        );

        psInfo[_target] = ProfitShareInfo({
            ratio: _psRatio,
            profit: 0,
            role: _psRole
        });

        emit BeneficiaryAdded(_target, _psRatio, _psRole);

        psList.add(_target);
    }


    /// Remove the target address from the beneciary list.
    /// The target address will no longer receive dividend.
    /// However, the target address can still claim the existing dividend.
    /// @param _target Address of the beneficiary that is being removed.
    function removeBeneficiary(
        address _target
    ) public adminPriviledged {

        require(
            isBeneficiary(_target),
            "IVSABU: target is not a beneficiary"
        );

        emit BeneficiaryRemoved(_target);
     
        psList.remove(_target);
    }

    /// Returns the length of the profit sharing list
    function psListLength() public view returns (uint256) {
        return psList.length();
    }

    /** Interacting with creditors */
    /// Creditor withdraws funds.
    /// If _baseAssetRequested is less than the asset that the vehicle can provide, 
    /// it will withraw as much as possible.
    /// @param _baseAssetRequested the amount of base asset requested by the creditor 
    /// @return The actual amount that the IV has sent back.
    function withdrawAsCreditor(
        uint256 _baseAssetRequested
    ) external override returns (uint256) {
        address _creditor = msg.sender;
        
        uint256 balance = baseAssetBalanceOf(_creditor);
        require(
            balance > 0,
            "IVSABU: Creditor has no balance."
        );
        
        // check if the creditor has enough funds.
        require(
            _baseAssetRequested <= balance,
            "IVSABU: Cannot request more than debt."
        );

        uint256 inVehicleBalance =
            IERC20Upgradeable(baseAsset).balanceOf(address(this));
        if (inVehicleBalance < _baseAssetRequested) {
            _pullFundsFromInvestment(_baseAssetRequested.sub(inVehicleBalance));
        }

        // _pullFundsFromInvestment is not guaranteed to pull the asked amount. 
        // (See the function description for more details)
        // Therefore, we need to check the baseAsset balance again, 
        /// and determine the amount to transfer.
        inVehicleBalance = IERC20Upgradeable(baseAsset).balanceOf(
            address(this)
        );

        uint256 balanceToTransfer = MathUpgradeable.min(_baseAssetRequested, inVehicleBalance);
        
        uint256 burnMe = baseAssetAsShareBalance(balanceToTransfer);
        shareBalance[_creditor] = shareBalance[_creditor].sub(burnMe);
        totalShares = totalShares.sub(burnMe);
        
        IERC20Upgradeable(baseAsset).safeTransfer(
            _creditor,
           balanceToTransfer
        );
        emit CreditorWithdrawn(_creditor, _baseAssetRequested, balanceToTransfer);
        return balanceToTransfer;
    }

    /// Creditor pushing more funds into vehicle
    /// returns how much funds was accepted by the vehicle.
    /// @param _amount the amount of base asset that the creditor wants to invest.
    /// @return The amount that was accepted by the IV. 
    function askToInvestAsCreditor(uint256 _amount) external onlyCreditor override returns(uint256) {
        address _creditor = msg.sender;
        IERC20Upgradeable(baseAsset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 mintMe = baseAssetAsShareBalance(_amount);
        shareBalance[_creditor] = shareBalance[_creditor].add(mintMe);
        totalShares = totalShares.add(mintMe);
        emit CreditorInvested(_creditor, _amount, mintMe);
        return _amount;
    }

    /** Interacting with underlying investment opportunities */
    /// Operator can use this to pull funds out from investment to ease the operation 
    /// such as moving the funds to another iv, emergency exit, etc.
    /// @param _amount the amount of funds that we are removing from the investment opportunity
    function pullFundsFromInvestment(uint256 _amount) external opsPriviledged {
        _pullFundsFromInvestment(_amount);
        emit OpsInvestmentPulled(_amount);
    }

    /// Pull the funds from the underlying investment opportunities.
    /// This function will do best effor to pull the requested amount of funds.
    /// However, the exact amount of funds pulled is not guaranteed.
    function _pullFundsFromInvestment(uint256 _amount) internal virtual; 

    function investAll() public opsPriviledged virtual {
        _investAll();
        emit OpsInvestAll();
    }

    function _investAll() internal virtual;

    /// Anyone can call the function when the IV has more debt
    /// than funds in the investment opportunity,
    /// this means that it has lost money and could file for insurance.
    /// The function would calculate the lost amount automatically, and call
    /// contracts that have provided insurance.
    /// If the loss is negligible, the function will not call the respective contracts.
    function fileInsuanceClaim() public {
        uint256 totalBalance = invested().add(IERC20Upgradeable(baseAsset).balanceOf(address(this)));
        uint256 totalDebtAmount = totalDebt();

        uint256 claimAmount = 0;
        if(totalBalance < totalDebtAmount) {
            claimAmount = totalDebtAmount.sub(totalBalance);
        }

        if(claimAmount < (totalDebtAmount / 10000)){
            claimAmount = 0; 
            // Calling _fileInsuranceClaimAmount with zero 
            // claim amount will unlock the previously locked insurance vault.

        }

        emit InsuranceClaimFiled(claimAmount);
        // If balance < debt, lock all the insurance vaults.
        // Otherwise, unlock all the insurance vaults.
        _fileInsuranceClaimAmount(claimAmount);
    }

    // The funds are locked on the insurance provider's side
    // This allows the liquidity that provides insurance to potentially
    // maximize its capital efficiency by insuring multiple independent investment vehicles
    function _fileInsuranceClaimAmount(uint256 _amount) internal {
        for(uint256 i = 0 ; i < psList.length(); i++) {
            address targetAddress = psList.at(i);
            if (psInfo[targetAddress].role == ROLE_INSURER){
                IInsuranceProvider(targetAddress).fileClaim(_amount);
            }
        }
    }

    /** Collecting profits */
    /// Operators can call this to account all the profit that has accumulated
    /// to all the creditors and beneficiaries of the IV.
    /// @param minBaseProfit the minimum profit that should be accounted.
    function collectProfitAndDistribute(uint256 minBaseProfit) external virtual opsPriviledged {
        // Withdraws native interests as baseAsset and collects FARM
        uint256 baseProfit = _collectProfitAsBaseAsset();
        require(baseProfit >= minBaseProfit, "IVSABU: profit did not achieve minBaseProfit");
        emit OpsCollectProfit(baseProfit);
        // profit accounting for baseAsset
        _accountProfit(baseProfit);

        // invest the baseAsset back
        _investAll();
    }

    function _collectProfitAsBaseAsset() internal virtual returns (uint256 baseAssetProfit);

    function _accountProfit(uint256 baseAssetProfit) internal {
        uint256 remaining = baseAssetProfit;

        for(uint256 i = 0 ; i < psList.length(); i++) {
            address targetAddress = psList.at(i);
            ProfitShareInfo storage targetInfo = psInfo[targetAddress];

            uint256 profitToTarget =
            baseAssetProfit.mul(targetInfo.ratio).div(RATIO_DENOMINATOR);

            targetInfo.profit = targetInfo.profit.add(profitToTarget);
            remaining = remaining.sub(profitToTarget);

        }

        sharePrice = sharePrice.add(remaining.mul(SHARE_UNIT).div(totalShares));
    }

    /** View functions */
    function invested() public view virtual returns (uint256);

    /// Returns the profit that has not been accounted.
    /// @return The pending profit in the investment opportunity yet to be accounted.
    function profitsPending() public view virtual returns (uint256);

    /// Converts IV share to amount in base asset
    /// @param _shareBalance the share amount
    /// @return the equivalent base asset amount
    function shareBalanceAsBaseAsset(
        uint256 _shareBalance
    ) public view returns (uint256) {
        return _shareBalance.mul(sharePrice).div(SHARE_UNIT);
    }

    /// Converts base asset amount to share amount
    /// @param _baseAssetAmount amount in base asset
    /// @return the equivalent share amount
    function baseAssetAsShareBalance(
        uint256 _baseAssetAmount
    ) public view returns (uint256) {
        return _baseAssetAmount.mul(SHARE_UNIT).div(sharePrice);
    }

    /// Returns base asset amount that an address holds
    /// @param _address the target address, could be a creditor or beneficiary.
    /// @return base asset amount of the target address
    function baseAssetBalanceOf(
        address _address
    ) public view override returns (uint256) {
        return shareBalanceAsBaseAsset(shareBalance[_address]);
    }

    /// Returns the total debt of the IV.
    /// @return the total debt of the IV. 
    function totalDebt() public view returns (uint256) {
        uint256 debt = shareBalanceAsBaseAsset(totalShares);
        for(uint256 i = 0 ; i < psList.length(); i++) {
            address targetAddress = psList.at(i);
            ProfitShareInfo storage targetInfo = psInfo[targetAddress];
            debt = debt.add(targetInfo.profit);
        }
        return debt;
    }
}
