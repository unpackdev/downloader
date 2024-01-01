// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PausableUpgradeable.sol";

import "./Ownable.sol";
import "./Math.sol";
import "./EnumerableSet.sol";

import "./PoolCalculations.sol";
import "./PoolTransfers.sol";
import "./ILendingPool.sol";

import "./IFeeSharing.sol";
import "./AuthorityAware.sol";
import "./TrancheVault.sol";

contract LendingPool is ILendingPool, AuthorityAware, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Math for uint;

    /*///////////////////////////////////
       CONSTANTS
    ///////////////////////////////////*/
    string public constant VERSION = "2023-06-12";

    uint internal constant WAD = 10 ** 18;
    uint internal constant DAY = 24 * 60 * 60;
    uint internal constant YEAR = 365 * DAY;

    // DO NOT TOUCH WITHOUT LIBRARY CONSIDERATIONS
    struct Rewardable {
        uint stakedAssets;
        uint lockedPlatformTokens;
        uint redeemedRewards;
        uint64 start;
    }

    struct RollOverSetting {
        bool enabled;
        bool principal;
        bool rewards;
        bool platformTokens;
    }

    enum Stages {                   // WARNING, DO NOT REORDER ENUM!!!
        INITIAL,                    // 0
        OPEN,                       // 1
        FUNDED,                     // 2
        FUNDING_FAILED,             // 3
        FLC_DEPOSITED,              // 4
        BORROWED,                   // 5
        BORROWER_INTEREST_REPAID,   // 6
        DELINQUENT,                 // 7
        REPAID,                     // 8
        DEFAULTED,                  // 9
        FLC_WITHDRAWN               // 10
    }

    struct LendingPoolParams {
        string name;
        string token;
        address stableCoinContractAddress;
        address platformTokenContractAddress;
        uint minFundingCapacity;
        uint maxFundingCapacity;
        uint64 fundingPeriodSeconds;
        uint64 lendingTermSeconds;
        address borrowerAddress;
        uint firstLossAssets;
        uint borrowerTotalInterestRateWad;
        uint repaymentRecurrenceDays;
        uint gracePeriodDays;
        uint protocolFeeWad;
        uint defaultPenalty;
        uint penaltyRateWad;
        uint8 tranchesCount;
        uint[] trancheAPRsWads;
        uint[] trancheBoostedAPRsWads;
        uint[] trancheBoostRatios;
        uint[] trancheCoveragesWads;
    }

    /*///////////////////////////////////
       CONTRACT VARIABLES
    ///////////////////////////////////*/
    /*Initializer parameters*/
    string public name;
    string public token;
    address public stableCoinContractAddress;
    address public platformTokenContractAddress;
    uint public minFundingCapacity;
    uint public maxFundingCapacity;
    uint64 public fundingPeriodSeconds;
    uint64 public lendingTermSeconds;
    address public borrowerAddress;
    uint public firstLossAssets;
    uint public repaymentRecurrenceDays;
    uint public gracePeriodDays;
    uint public borrowerTotalInterestRateWad;
    uint public protocolFeeWad;
    uint public defaultPenalty;
    uint public penaltyRateWad;
    uint8 public tranchesCount;
    uint[] public trancheAPRsWads;
    uint[] public trancheBoostedAPRsWads;
    uint[] public trancheBoostRatios;
    uint[] public trancheCoveragesWads;
    /* Other contract addresses */
    address public poolFactoryAddress;
    address public feeSharingContractAddress;
    address[] public trancheVaultAddresses;
    /* Some Timestamps */
    uint64 public openedAt;
    uint64 public fundedAt;
    uint64 public fundingFailedAt;
    uint64 public flcDepositedAt;
    uint64 public borrowedAt;
    uint64 public repaidAt;
    uint64 public flcWithdrawntAt;
    uint64 public defaultedAt;

    /* Interests & Yields */
    uint public collectedAssets;
    uint public borrowedAssets;
    uint public borrowerInterestRepaid;

    EnumerableSet.AddressSet internal s_lenders;

    /// @dev trancheId => (lenderAddress => RewardableRecord)
    mapping(uint8 => mapping(address => Rewardable)) public s_trancheRewardables;

    /// @dev trancheId => stakedassets
    mapping(uint8 => uint256) public s_totalStakedAssetsByTranche;

    /// @dev trancheId => lockedTokens
    mapping(uint8 => uint256) public s_totalLockedPlatformTokensByTranche;

    /// @dev lenderAddress => RollOverSetting
    mapping(address => RollOverSetting) private s_rollOverSettings;

    Stages public currentStage;

    /*///////////////////////////////////
       MODIFIERS
    ///////////////////////////////////*/

    modifier authTrancheVault(uint8 id) {
        _authTrancheVault(id);
        _;
    }

    function _authTrancheVault(uint8 id) internal view {
        require(id < trancheVaultAddresses.length, "LP001"); // "LendingPool: invalid trancheVault id"
        require(trancheVaultAddresses[id] == _msgSender(), "LP002"); // "LendingPool: trancheVault auth"
    }

    modifier onlyPoolBorrower() {
        _onlyPoolBorrower();
        _;
    }

    function _onlyPoolBorrower() internal view {
        require(_msgSender() == borrowerAddress, "LP003"); // "LendingPool: not a borrower"
    }

    modifier atStage(Stages _stage) {
        _atStage(_stage);
        _;
    }

    function _atStage(Stages _stage) internal view {
        require(currentStage == _stage, "LP004"); // "LendingPool: not at correct stage"
    }

    modifier atStages2(Stages _stage1, Stages _stage2) {
        _atStages2(_stage1, _stage2);
        _;
    }

    function _atStages2(Stages _stage1, Stages _stage2) internal view {
        require(currentStage == _stage1 || currentStage == _stage2, "LP004"); // "LendingPool: not at correct stage"
    }

    modifier atStages3(
        Stages _stage1,
        Stages _stage2,
        Stages _stage3
    ) {
        _atStages3(_stage1, _stage2, _stage3);
        _;
    }

    function _atStages3(Stages _stage1, Stages _stage2, Stages _stage3) internal view {
        require(
            currentStage == _stage1 || currentStage == _stage2 || currentStage == _stage3,
            "LP004" // "LendingPool: not at correct stage"
        );
    }

    /*///////////////////////////////////
       EVENTS
    ///////////////////////////////////*/

    // State Changes //
    event PoolInitialized(
        LendingPoolParams params,
        address[] _trancheVaultAddresses,
        address _feeSharingContractAddress,
        address _authorityAddress
    );
    event PoolOpen(uint64 openedAt);
    event PoolFunded(uint64 fundedAt, uint collectedAssets);
    event PoolFundingFailed(uint64 fundingFailedAt);
    event PoolRepaid(uint64 repaidAt);
    event PoolDefaulted(uint64 defaultedAt);
    event PoolFirstLossCapitalWithdrawn(uint64 flcWithdrawntAt);

    // Lender //
    event LenderDeposit(address indexed lender, uint8 indexed trancheId, uint256 amount);
    event LenderWithdraw(address indexed lender, uint8 indexed trancheId, uint256 amount);
    event LenderWithdrawInterest(address indexed lender, uint8 indexed trancheId, uint256 amount);
    event LenderTrancheRewardsChange(
        address indexed lender,
        uint8 indexed trancheId,
        uint lenderEffectiveAprWad,
        uint totalExpectedRewards,
        uint redeemedRewards
    );
    event LenderLockPlatformTokens(address indexed lender, uint8 indexed trancheId, uint256 amount);
    event LenderUnlockPlatformTokens(address indexed lender, uint8 indexed trancheId, uint256 amount);

    // Borrower //
    event BorrowerDepositFirstLossCapital(address indexed borrower, uint amount);
    event BorrowerBorrow(address indexed borrower, uint amount);
    event BorrowerPayInterest(
        address indexed borrower,
        uint amount,
        uint lendersDistributedAmount,
        uint feeSharingContractAmount
    );
    event BorrowerPayPenalty(address indexed borrower, uint amount);
    event BorrowerRepayPrincipal(address indexed borrower, uint amount);
    event BorrowerWithdrawFirstLossCapital(address indexed borrower, uint amount);

    /*///////////////////////////////////
       INITIALIZATION
    ///////////////////////////////////*/

    function initialize(
        LendingPoolParams calldata params,
        address[] calldata _trancheVaultAddresses,
        address _feeSharingContractAddress,
        address _authorityAddress,
        address _poolFactoryAddress
    ) external initializer {
        PoolCalculations.validateInitParams(
            params,
            _trancheVaultAddresses,
            _feeSharingContractAddress,
            _authorityAddress
        );

        PoolCalculations.validateWad(params.trancheCoveragesWads);

        name = params.name;
        token = params.token;
        stableCoinContractAddress = params.stableCoinContractAddress;
        platformTokenContractAddress = params.platformTokenContractAddress;
        minFundingCapacity = params.minFundingCapacity;
        maxFundingCapacity = params.maxFundingCapacity;
        fundingPeriodSeconds = params.fundingPeriodSeconds;
        lendingTermSeconds = params.lendingTermSeconds;
        borrowerAddress = params.borrowerAddress;
        firstLossAssets = params.firstLossAssets;
        borrowerTotalInterestRateWad = params.borrowerTotalInterestRateWad;
        repaymentRecurrenceDays = params.repaymentRecurrenceDays;
        gracePeriodDays = params.gracePeriodDays;
        protocolFeeWad = params.protocolFeeWad;
        defaultPenalty = params.defaultPenalty;
        penaltyRateWad = params.penaltyRateWad;
        tranchesCount = params.tranchesCount;
        trancheAPRsWads = params.trancheAPRsWads;
        trancheBoostedAPRsWads = params.trancheBoostedAPRsWads;
        trancheBoostRatios = params.trancheBoostRatios;
        trancheCoveragesWads = params.trancheCoveragesWads;

        trancheVaultAddresses = _trancheVaultAddresses;
        feeSharingContractAddress = _feeSharingContractAddress;
        poolFactoryAddress = _poolFactoryAddress;

        __Ownable_init();
        __Pausable_init();
        __AuthorityAware__init(_authorityAddress);

        emit PoolInitialized(params, _trancheVaultAddresses, _feeSharingContractAddress, _authorityAddress);
    }

    /*///////////////////////////////////
       ADMIN FUNCTIONS
    ///////////////////////////////////*/

    /** @dev Pauses the pool */
    function pause() external onlyOwnerOrAdmin {
        _pause();
    }

    /** @dev Unpauses the pool */
    function unpause() external onlyOwnerOrAdmin {
        _unpause();
    }

    /** @notice Marks the pool as opened. This function has to be called by *owner* when
     * - sets openedAt to current block timestamp
     * - enables deposits and withdrawals to tranche vaults
     */
    function adminOpenPool() external onlyOwnerOrAdmin atStage(Stages.FLC_DEPOSITED) whenNotPaused {
        openedAt = uint64(block.timestamp);
        currentStage = Stages.OPEN;

        TrancheVault[] memory vaults = trancheVaultContracts();

        for (uint i; i < trancheVaultAddresses.length; i++) {
            vaults[i].enableDeposits();
            vaults[i].enableWithdrawals();
        }

        emit PoolOpen(openedAt);
    }

    /** @notice Checks whether the pool was funded successfully or not.
     *  this function is expected to be called by *owner* once the funding period ends
     */
    function adminTransitionToFundedState() external onlyOwnerOrAdmin atStage(Stages.OPEN) {
        require(block.timestamp >= openedAt + fundingPeriodSeconds, "Cannot accrue interest or declare failure before start time");
        if (collectedAssets >= minFundingCapacity) {
            _transitionToFundedStage();
        } else {
            _transitionToFundingFailedStage();
        }
    }

    function adminTransitionToDefaultedState() external onlyOwnerOrAdmin atStage(Stages.BORROWED) {
        require(block.timestamp >= fundedAt + lendingTermSeconds, "LP023"); // "LendingPool: maturityDate not reached"
        _transitionToDefaultedStage();
    }

    function _transitionToFundedStage() internal whenNotPaused {
        fundedAt = uint64(block.timestamp);
        currentStage = Stages.FUNDED;

        TrancheVault[] memory vaults = trancheVaultContracts();

        for (uint i; i < vaults.length; i++) {
            TrancheVault tv = vaults[i];
            tv.disableDeposits();
            tv.disableWithdrawals();
            tv.sendAssetsToPool(tv.totalAssets());
        }

        emit PoolFunded(fundedAt, collectedAssets);
    }

    function _transitionToFundingFailedStage() internal whenNotPaused {
        fundingFailedAt = uint64(block.timestamp);
        currentStage = Stages.FUNDING_FAILED;
        
        TrancheVault[] memory vaults = trancheVaultContracts();

        for (uint i; i < trancheVaultAddresses.length; i++) {
            vaults[i].disableDeposits();
            vaults[i].enableWithdrawals();
        }
        emit PoolFundingFailed(fundingFailedAt);
    }

    function _transitionToFlcDepositedStage(uint flcAssets) internal whenNotPaused {
        flcDepositedAt = uint64(block.timestamp);
        currentStage = Stages.FLC_DEPOSITED;
        emit BorrowerDepositFirstLossCapital(borrowerAddress, flcAssets);
    }

    function _transitionToBorrowedStage(uint amountToBorrow) internal whenNotPaused {
        borrowedAt = uint64(block.timestamp);
        borrowedAssets = amountToBorrow;
        currentStage = Stages.BORROWED;

        emit BorrowerBorrow(borrowerAddress, amountToBorrow);
    }

    function _transitionToPrincipalRepaidStage(uint repaidPrincipal) internal whenNotPaused {
        repaidAt = uint64(block.timestamp);
        currentStage = Stages.REPAID;
        emit BorrowerRepayPrincipal(borrowerAddress, repaidPrincipal);
        emit PoolRepaid(repaidAt);
    }

    function _transitionToFlcWithdrawnStage(uint flcAssets) internal whenNotPaused {
        flcWithdrawntAt = uint64(block.timestamp);
        currentStage = Stages.FLC_WITHDRAWN;
        emit BorrowerWithdrawFirstLossCapital(borrowerAddress, flcAssets);
    }

    function _claimTrancheInterestForLender(address lender, uint8 trancheId) internal {
        uint rewards = lenderRewardsByTrancheRedeemable(lender, trancheId);
        if (rewards > 0) {
            s_trancheRewardables[trancheId][lender].redeemedRewards += rewards;
            SafeERC20.safeTransfer(_stableCoinContract(), lender, rewards);
            emit LenderWithdrawInterest(lender, trancheId, rewards);
        }
    }

    function _claimInterestForAllLenders() internal {
        TrancheVault[] memory vaults = trancheVaultContracts();

        for (uint8 i; i < tranchesCount; i++) {
            for (uint j; j < lenderCount(); j++) {
                _claimTrancheInterestForLender(lendersAt(j), vaults[i].id());
            }
        }
    }

    /**
     * @notice Transitions the pool to the defaulted state and pays out remaining assets to the tranche vaults
     * @dev This function is expected to be called by *owner* after the maturity date has passed and principal has not been repaid
     */
    function _transitionToDefaultedStage() internal whenNotPaused {
        defaultedAt = uint64(block.timestamp);
        currentStage = Stages.DEFAULTED;
        _claimInterestForAllLenders();
        // TODO: update repaid interest to be the total interest paid to lenders
        // TODO: should the protocol fees be paid in event of default
        uint availableAssets = _stableCoinContract().balanceOf(address(this));
        TrancheVault[] memory vaults = trancheVaultContracts();

        for (uint i; i < trancheVaultAddresses.length; i++) {
            TrancheVault tv = vaults[i];
            uint assetsToSend = (trancheCoveragesWads[i] * availableAssets) / WAD;
            uint trancheDefaultRatioWad = (assetsToSend * WAD) / tv.totalAssets();

            if (assetsToSend > 0) {
                SafeERC20.safeTransfer(_stableCoinContract(), address(tv), assetsToSend);
            }
            availableAssets -= assetsToSend;
            tv.setDefaultRatioWad(trancheDefaultRatioWad);
            tv.enableWithdrawals();
        }

        emit PoolDefaulted(defaultedAt);
    }

    /*///////////////////////////////////
      Lender (please also see onTrancheDeposit() and onTrancheWithdraw())
      Error group: 1
    ///////////////////////////////////*/

    /** @notice Lock platform tokens in order to get APR boost
     *  @param trancheId tranche id
     *  @param platformTokens amount of PLATFORM tokens to lock
     */
    function lenderLockPlatformTokensByTranche(
        uint8 trancheId,
        uint platformTokens
    ) external onlyLender atStage(Stages.OPEN) whenNotPaused {
        require(
            platformTokens <= lenderPlatformTokensByTrancheLockable(_msgSender(), trancheId),
            "LP101" //"LendingPool: lock will lead to overboost"
        );
        require(IERC20(platformTokenContractAddress).totalSupply() > 0, "Lock: Token Locking Disabled");

        Rewardable storage r = s_trancheRewardables[trancheId][_msgSender()];
        r.lockedPlatformTokens += platformTokens;
        s_totalLockedPlatformTokensByTranche[trancheId] += platformTokens;

        SafeERC20.safeTransferFrom(IERC20(platformTokenContractAddress), _msgSender(), address(this), platformTokens);

        emit LenderLockPlatformTokens(_msgSender(), trancheId, platformTokens);
        _emitLenderTrancheRewardsChange(_msgSender(), trancheId);
    }

    /** @notice Unlock platform tokens after the pool is repaid AND rewards are redeemed
     *  @param trancheId tranche id
     *  @param platformTokens amount of PLATFORM tokens to unlock
     */
    function lenderUnlockPlatformTokensByTranche(
        uint8 trancheId,
        uint platformTokens
    ) external onlyLender atStages2(Stages.REPAID, Stages.FLC_WITHDRAWN) whenNotPaused {
        require(!s_rollOverSettings[msg.sender].platformTokens, "LP102"); // "LendingPool: tokens are locked for rollover"
        require(lenderRewardsByTrancheRedeemable(_msgSender(), trancheId) == 0, "LP103"); // "LendingPool: rewards not redeemed"
        require(IERC20(platformTokenContractAddress).totalSupply() > 0, "Unlock: Token Locking Disabled");

        Rewardable storage r = s_trancheRewardables[trancheId][_msgSender()];

        require(r.lockedPlatformTokens >= platformTokens, "LP104"); // LendingPool: not enough locked tokens"
        r.lockedPlatformTokens -= platformTokens;

        SafeERC20.safeTransfer(IERC20(platformTokenContractAddress), _msgSender(), platformTokens);

        emit LenderUnlockPlatformTokens(_msgSender(), trancheId, platformTokens);
    }

    /** @notice Redeem currently available rewards for a tranche
     *  @param trancheId tranche id
     *  @param toWithdraw amount of rewards to withdraw
     */
    function lenderRedeemRewardsByTranche(
        uint8 trancheId,
        uint toWithdraw
    ) public onlyLender atStages3(Stages.BORROWED, Stages.REPAID, Stages.FLC_WITHDRAWN) whenNotPaused {
        require(!s_rollOverSettings[msg.sender].rewards, "LP105"); // "LendingPool: rewards are locked for rollover"
        if (toWithdraw == 0) {
            return;
        }
        uint maxWithdraw = lenderRewardsByTrancheRedeemable(_msgSender(), trancheId);
        require(toWithdraw <= maxWithdraw, "LP106"); // "LendingPool: amount to withdraw is too big"
        s_trancheRewardables[trancheId][_msgSender()].redeemedRewards += toWithdraw;

        SafeERC20.safeTransfer(_stableCoinContract(), _msgSender(), toWithdraw);

        // if (IERC20(stableCoinContractAddress()).balanceOf(address(this)) < poolBalanceThreshold()) {
        //     _transitionToDelinquentStage();
        // }

        emit LenderWithdrawInterest(_msgSender(), trancheId, toWithdraw);
        _emitLenderTrancheRewardsChange(_msgSender(), trancheId);
    }

    /** @notice Redeem currently available rewards for two tranches
     *  @param toWithdraws amount of rewards to withdraw accross all tranches
     */
    function lenderRedeemRewards(
        uint[] calldata toWithdraws
    ) external onlyLender atStages3(Stages.BORROWED, Stages.REPAID, Stages.FLC_WITHDRAWN) whenNotPaused {
        require(!s_rollOverSettings[msg.sender].rewards, "LP105"); //"LendingPool: rewards are locked for rollover"
        require(toWithdraws.length == tranchesCount, "LP107"); //"LendingPool: wrong amount of tranches"
        for (uint8 i; i < toWithdraws.length; i++) {
            lenderRedeemRewardsByTranche(i, toWithdraws[i]);
        }
    }

    /* VIEWS */

    /// @notice average APR of all lenders across all tranches, boosted or not
    function allLendersInterest() public view returns (uint) {
        return (((allLendersEffectiveAprWad() * collectedAssets) / WAD) * lendingTermSeconds) / YEAR;
    }

    function allLendersInterestByDate() public view returns (uint) {
        return PoolCalculations.allLendersInterestByDate(this);
    }

    /// @notice average APR of all lenders across all tranches, boosted or not
    function allLendersEffectiveAprWad() public view returns (uint) {
        return PoolCalculations.allLendersEffectiveAprWad(this, tranchesCount);
    }

    /// @notice weighted APR accross all the lenders
    function lenderTotalAprWad(address lenderAddress) public view returns (uint) {
        return PoolCalculations.lenderTotalAprWad(this, lenderAddress);
    }

    /// @notice  Returns amount of stablecoins deposited across all the pool tranches by a lender
    function lenderAllDepositedAssets(address lenderAddress) public view returns (uint totalAssets) {
        totalAssets = 0;
        for (uint8 i; i < tranchesCount; ++i) {
            totalAssets += s_trancheRewardables[i][lenderAddress].stakedAssets;
        }
    }

    /* VIEWS BY TRANCHE*/

    /** @notice  Returns amount of stablecoins deposited to a pool tranche by a lender
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderDepositedAssetsByTranche(address lenderAddress, uint8 trancheId) public view returns (uint) {
        return s_trancheRewardables[trancheId][lenderAddress].stakedAssets;
    }

    /** @notice Returns amount of stablecoins to be paid for the lender by the end of the pool term.
     *  `lenderAPR * lenderDepositedAssets * lendingTermSeconds / YEAR`
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderTotalExpectedRewardsByTranche(address lenderAddress, uint8 trancheId) public view returns (uint) {
        return
            PoolCalculations.lenderTotalExpectedRewardsByTranche(
                lenderDepositedAssetsByTranche(lenderAddress, trancheId),
                lenderEffectiveAprByTrancheWad(lenderAddress, trancheId),
                lendingTermSeconds
            );
    }

    /** @notice Returns amount of stablecoin rewards generated for the lenders by current second.
     *  `lenderTotalExpectedRewardsByTranche * (secondsElapsed / lendingTermSeconds)`
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderRewardsByTrancheGeneratedByDate(address lenderAddress, uint8 trancheId) public view returns (uint) {
        return PoolCalculations.lenderRewardsByTrancheGeneratedByDate(this, lenderAddress, trancheId);
    }

    /** @notice Returns amount of stablecoin rewards that has been withdrawn by the lender.
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderRewardsByTrancheRedeemed(address lenderAddress, uint8 trancheId) public view returns (uint) {
        return s_trancheRewardables[trancheId][lenderAddress].redeemedRewards;
    }

    /** @notice Returns amount of stablecoin rewards that can be withdrawn by the lender. (generated - redeemed). Special means this one is distinguished from the FE version and is only used within the SCs
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderRewardsByTrancheRedeemable(address lenderAddress, uint8 trancheId) public view returns (uint) {
        uint256 willReward = lenderRewardsByTrancheGeneratedByDate(lenderAddress, trancheId);
        uint256 hasRewarded = lenderRewardsByTrancheRedeemed(lenderAddress, trancheId);
        return willReward - hasRewarded;
    }

    /** @notice Returns amount of stablecoin rewards that can be withdrawn by the lender. (generated - redeemed) only use in FE
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderRewardsByTrancheRedeemableSpecial(address lenderAddress, uint8 trancheId) public view returns (uint) {
        uint256 willReward = lenderRewardsByTrancheGeneratedByDate(lenderAddress, trancheId);
        uint256 hasRewarded = lenderRewardsByTrancheRedeemed(lenderAddress, trancheId);
        if(hasRewarded > willReward) {
            return 0;
        }
        return willReward - hasRewarded;
    }

    /** @notice Returns APR for the lender taking into account all the deposited USDC + platform tokens
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderEffectiveAprByTrancheWad(address lenderAddress, uint8 trancheId) public view returns (uint) {
        return PoolCalculations.lenderEffectiveAprByTrancheWad(this, lenderAddress, trancheId);
    }

    /** @notice Returns amount of platform tokens locked by the lender
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderPlatformTokensByTrancheLocked(address lenderAddress, uint8 trancheId) public view returns (uint) {
        return s_trancheRewardables[trancheId][lenderAddress].lockedPlatformTokens;
    }

    /** @notice Returns amount of staked tokens committed by the lender
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderStakedTokensByTranche(address lenderAddress, uint8 trancheId) public view returns (uint) {
        return s_trancheRewardables[trancheId][lenderAddress].stakedAssets;
    }

    /** @notice Returns amount of platform tokens that lender can lock in order to boost their APR
     *  @param lenderAddress lender address
     *  @param trancheId tranche id
     */
    function lenderPlatformTokensByTrancheLockable(address lenderAddress, uint8 trancheId) public view returns (uint) {
        Rewardable storage r = s_trancheRewardables[trancheId][lenderAddress];
        uint maxLockablePlatformTokens = r.stakedAssets * trancheBoostRatios[trancheId];
        return maxLockablePlatformTokens - r.lockedPlatformTokens;
    }

    /*///////////////////////////////////
       Rollover settings
    ///////////////////////////////////*/
    /** @notice marks the intent of the lender to roll over their capital to the upcoming pool (called by older pool)
     *  if you opt to roll over you will not be able to withdraw stablecoins / platform tokens from the pool
     *  @param principal whether the principal should be rolled over
     *  @param rewards whether the rewards should be rolled over
     *  @param platformTokens whether the platform tokens should be rolled over
     */
    function lenderEnableRollOver(bool principal, bool rewards, bool platformTokens) external onlyLender {
        address lender = _msgSender();
        s_rollOverSettings[lender] = RollOverSetting(true, principal, rewards, platformTokens);
        PoolTransfers.lenderEnableRollOver(this, principal, rewards, platformTokens, lender);
    }

    /**
     * @dev This function rolls funds from prior deployments into currently active deployments
     * @param deadLendingPoolAddr The address of the lender whose funds are transfering over to the new lender
     * @param deadTrancheAddrs The address of the tranches whose funds are mapping 1:1 with the next traches
     * @param lenderStartIndex The first lender to start migrating over
     * @param lenderEndIndex The last lender to migrate
     */
    function executeRollover(
        address deadLendingPoolAddr,
        address[] memory deadTrancheAddrs,
        uint256 lenderStartIndex,
        uint256 lenderEndIndex
    ) external onlyOwnerOrAdmin atStage(Stages.OPEN) whenNotPaused {
        PoolTransfers.executeRollover(this, deadLendingPoolAddr, deadTrancheAddrs, lenderStartIndex, lenderEndIndex);
    }

    /** @notice cancels lenders intent to roll over the funds to the next pool.
     */
    function lenderDisableRollOver() external onlyLender {
        s_rollOverSettings[_msgSender()] = RollOverSetting(false, false, false, false);
    }

    /** @notice returns lender's roll over settings
     *  @param lender lender address
     */
    function lenderRollOverSettings(address lender) external view returns (RollOverSetting memory) {
        return s_rollOverSettings[lender];
    }

    /*///////////////////////////////////
       Borrower functions
       Error group: 2
    ///////////////////////////////////*/
    /** @notice Deposits first loss capital into the pool
     *  should be called by the borrower before the pool can start
     */
    function borrowerDepositFirstLossCapital() external onlyPoolBorrower atStage(Stages.INITIAL) whenNotPaused {
        _transitionToFlcDepositedStage(firstLossAssets);
        SafeERC20.safeTransferFrom(_stableCoinContract(), msg.sender, address(this), firstLossAssets);
    }

    /** @notice Borrows collected funds from the pool */
    function borrow() external onlyPoolBorrower atStage(Stages.FUNDED) whenNotPaused {
        _transitionToBorrowedStage(collectedAssets);
        SafeERC20.safeTransfer(_stableCoinContract(), borrowerAddress, collectedAssets);
    }

    /** @notice Lets the borrower withdraw first loss deposit in the event of funding failed */
    function borrowerRecoverFirstLossCapital() external atStage(Stages.FUNDING_FAILED) {
        uint256 copyFirstLossAssets = firstLossAssets;
        firstLossAssets = 0;
        SafeERC20.safeTransfer(_stableCoinContract(), borrowerAddress, copyFirstLossAssets);
    }

    /** @notice Make an interest payment.
     *  If the pool is delinquent, the minimum payment is penalty + whatever interest that needs to be paid to bring the pool back to healthy state
     */
    function borrowerPayInterest(uint assets) external onlyPoolBorrower whenNotPaused {
        uint penalty = borrowerPenaltyAmount();
        require(penalty < assets, "LP201"); // "LendingPool: penalty cannot be more than assets"

        if (penalty > 0) {
            uint balanceDifference = poolBalanceThreshold() - poolBalance();
            require(assets >= penalty + balanceDifference, "LP202"); // "LendingPool: penalty+interest will not bring pool to healthy state"
        }

        uint feeableInterestAmount = assets - penalty;
        if (feeableInterestAmount > borrowerOutstandingInterest()) {
            feeableInterestAmount = borrowerOutstandingInterest();
        }

        uint assetsToSendToFeeSharing = (feeableInterestAmount * protocolFeeWad) / WAD + penalty;
        uint assetsForLenders = assets - assetsToSendToFeeSharing;

        borrowerInterestRepaid = borrowerInterestRepaid + assets - penalty;

        if (assetsToSendToFeeSharing > 0) {
            SafeERC20.safeTransfer(_stableCoinContract(), feeSharingContractAddress, assetsToSendToFeeSharing);
        }

        SafeERC20.safeTransferFrom(_stableCoinContract(), _msgSender(), address(this), assets);

        if (penalty > 0) {
            emit BorrowerPayPenalty(_msgSender(), penalty);
        }

        emit BorrowerPayInterest(borrowerAddress, assets, assetsForLenders, assetsToSendToFeeSharing);
    }

    /** @notice Repay principal
     *  can be called only after all interest is paid
     *  can be called only after all penalties are paid
     */
    function borrowerRepayPrincipal() external onlyPoolBorrower atStage(Stages.BORROWED) whenNotPaused {
        require(borrowerOutstandingInterest() == 0, "LP203"); // "LendingPool: interest must be paid before repaying principal"
        require(borrowerPenaltyAmount() == 0, "LP204"); // "LendingPool: penalty must be paid before repaying principal"

        _transitionToPrincipalRepaidStage(borrowedAssets);
        TrancheVault[] memory vaults = trancheVaultContracts();

        SafeERC20.safeTransferFrom(_stableCoinContract(), _msgSender(), address(this), borrowedAssets);
        for (uint i; i < tranchesCount; ++i) {
            TrancheVault tv = vaults[i];
            SafeERC20.safeTransfer(_stableCoinContract(), address(tv), tv.totalAssets());
            tv.enableWithdrawals();
        }
    }

    /** @notice Withdraw first loss capital and excess spread
     *  can be called only after principal is repaid
     */
    function borrowerWithdrawFirstLossCapitalAndExcessSpread() external onlyPoolBorrower atStage(Stages.REPAID) whenNotPaused {
        uint assetsToSend = firstLossAssets + borrowerExcessSpread();
        _transitionToFlcWithdrawnStage(assetsToSend);
        SafeERC20.safeTransfer(_stableCoinContract(), borrowerAddress, assetsToSend);
    }

    /* VIEWS */
    /** @notice Pool balance threshold.
     *  if pool balance fallse below this threshold, the pool is considered delinquent and the borrower starts to face penalties.
     */
    function poolBalanceThreshold() public view returns (uint) {
        return PoolCalculations.poolBalanceThreshold(this);
    }

    /** @notice Pool balance
     * First loss capital minus whatever rewards are generated for the lenders by date.
     */
    function poolBalance() public view returns (uint) {
        return PoolCalculations.poolBalance(this);
    }

    function lendersAt(uint i) public view returns (address) {
        return s_lenders.at(i);
    }

    function lenderCount() public view returns (uint256) {
        return s_lenders.length();
    }

    /** @notice how much penalty the borrower owes because of the delinquency fact */
    function borrowerPenaltyAmount() public view returns (uint) {
        if(currentStage > Stages.FLC_DEPOSITED) {
            return PoolCalculations.borrowerPenaltyAmount(this);
        }
    }

    /** @dev total interest to be paid by borrower = adjustedBorrowerAPR * collectedAssets
     *  @return interest amount of assets to be repaid
     */
    function borrowerExpectedInterest() public view returns (uint) {
        return PoolCalculations.borrowerExpectedInterest(collectedAssets, borrowerAdjustedInterestRateWad());
    }

    /** @dev outstanding borrower interest = expectedBorrowerInterest - borrowerInterestAlreadyPaid
     *  @return interest amount of outstanding assets to be repaid
     */
    function borrowerOutstandingInterest() public view returns (uint) {
        return PoolCalculations.borrowerOutstandingInterest(borrowerInterestRepaid, borrowerExpectedInterest());
    }

    /** @notice excess spread = interest paid by borrower - interest paid to lenders - fees
     *  Once the pool ends, can be withdrawn by the borrower alongside the first loss capital
     */
    function borrowerExcessSpread() public view returns (uint) {
        return PoolCalculations.borrowerExcessSpread(this);
    }

    /** @dev adjusted borrower interest rate = APR * duration / 365 days
     *  @return adj borrower interest rate adjusted by duration of the loan
     */
    function borrowerAdjustedInterestRateWad() public view returns (uint adj) {
        return PoolCalculations.borrowerAdjustedInterestRateWad(borrowerTotalInterestRateWad, lendingTermSeconds);
    }

    /*///////////////////////////////////
       COMMUNICATION WITH VAULTS
       Error group: 3
    ///////////////////////////////////*/

    /// @dev TrancheVault will call that callback function when a lender deposits assets
    function onTrancheDeposit(
        uint8 trancheId,
        address depositorAddress,
        uint amount
    ) external authTrancheVault(trancheId) {
        // 1. find / create the rewardable
        Rewardable storage rewardable = s_trancheRewardables[trancheId][depositorAddress];

        // 2. add lender to the lenders set
        s_lenders.add(depositorAddress);

        // 3. add to the staked assets
        rewardable.stakedAssets += amount;
        collectedAssets += amount;
        s_totalStakedAssetsByTranche[trancheId] += amount;

        // 4. set the start of the rewardable
        rewardable.start = uint64(block.timestamp);

        emit LenderDeposit(depositorAddress, trancheId, amount);
        _emitLenderTrancheRewardsChange(depositorAddress, trancheId);
    }

    /// @dev TrancheVault will call that callback function when a lender withdraws assets
    function onTrancheWithdraw(
        uint8 trancheId,
        address depositorAddress,
        uint amount
    ) external authTrancheVault(trancheId) whenNotPaused {
        require(!s_rollOverSettings[depositorAddress].principal, "LP301"); // "LendingPool: principal locked for rollover"

        if (currentStage == Stages.REPAID || currentStage == Stages.FLC_WITHDRAWN) {
            emit LenderWithdraw(depositorAddress, trancheId, amount);
        } else {
            Rewardable storage rewardable = s_trancheRewardables[trancheId][depositorAddress];

            assert(rewardable.stakedAssets >= amount);

            rewardable.stakedAssets -= amount;
            collectedAssets -= amount;
            s_totalStakedAssetsByTranche[trancheId] -= amount;

            if (rewardable.stakedAssets == 0) {
                s_lenders.remove(depositorAddress);
            }
            emit LenderWithdraw(depositorAddress, trancheId, amount);
            _emitLenderTrancheRewardsChange(depositorAddress, trancheId);
        }
    }

    /*///////////////////////////////////
       HELPERS
    ///////////////////////////////////*/

    function trancheVaultContracts() internal view returns (TrancheVault[] memory) {
        return PoolCalculations.trancheVaultContracts(this);
    }

    function _emitLenderTrancheRewardsChange(address lenderAddress, uint8 trancheId) internal {
        emit LenderTrancheRewardsChange(
            lenderAddress,
            trancheId,
            lenderEffectiveAprByTrancheWad(lenderAddress, trancheId),
            lenderTotalExpectedRewardsByTranche(lenderAddress, trancheId),
            lenderRewardsByTrancheRedeemed(lenderAddress, trancheId)
        );
    }

    function _stableCoinContract() internal view returns (IERC20) {
        return IERC20(stableCoinContractAddress);
    }
}
