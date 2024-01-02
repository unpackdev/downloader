// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IBorrowerOperations.sol";
import "./IStabilityPool.sol";
import "./IBorrowerOperations.sol";
import "./ITroveManager.sol";
import "./ICollateralManager.sol";
import "./IUSDEToken.sol";
import "./ISortedTroves.sol";
import "./ICommunityIssuance.sol";
import "./IWETH.sol";
import "./ERDBase.sol";
import "./Errors.sol";
import "./DataTypes.sol";

/*
 * The Stability Pool holds USDE tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its USDE debt gets offset with
 * USDE in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of USDE tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a USDE loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH/wrapperETH gain, as the ETH/wrapperETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total USDE in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 *
 * --- IMPLEMENTATION ---
 *
 * We use a highly scalable method of tracking deposits and ETH/wrapperETH gains that has O(1) complexity.
 *
 * When a liquidation occurs, rather than updating each depositor's deposit and ETH/wrapperETH gain, we simply update two state variables:
 * a product P, and a sum S.
 *
 * A mathematical manipulation allows us to factor out the initial deposit, and accurately track all depositors' compounded deposits
 * and accumulated ETH/wrapperETH gains over time, as liquidations occur, using just these two variables P and S. When depositors join the
 * Stability Pool, they get a snapshot of the latest P and S: P_t and S_t, respectively.
 *
 * For a given deposit d_t, the ratio P/P_t tells us the factor by which a deposit has decreased since it joined the Stability Pool,
 * and the term d_t * (S - S_t)/P_t gives us the deposit's total accumulated ETH/wrapperETH gain.
 *
 * Each liquidation updates the product P and sum S. After a series of liquidations, a compounded deposit and corresponding ETH/wrapperETH gain
 * can be calculated using the initial deposit, the depositor’s snapshots of P and S, and the latest values of P and S.
 *
 * Any time a depositor updates their deposit (withdrawal, top-up) their accumulated ETH/wrapperETH gain is paid out, their new deposit is recorded
 * (based on their latest compounded deposit and modified by the withdrawal/top-up), and they receive new snapshots of the latest P and S.
 * Essentially, they make a fresh deposit that overwrites the old one.
 *
 *
 * --- SCALE FACTOR ---
 *
 * Since P is a running product in range ]0,1] that is always-decreasing, it should never reach 0 when multiplied by a number in range ]0,1[.
 * Unfortunately, Solidity floor division always reaches 0, sooner or later.
 *
 * A series of liquidations that nearly empty the Pool (and thus each multiply P by a very small number in range ]0,1[ ) may push P
 * to its 18 digit decimal limit, and round it to 0, when in fact the Pool hasn't been emptied: this would break deposit tracking.
 *
 * So, to track P accurately, we use a scale factor: if a liquidation would cause P to decrease to <1e-9 (and be rounded to 0 by Solidity),
 * we first multiply P by 1e9, and increment a currentScale factor by 1.
 *
 * The added benefit of using 1e9 for the scale factor (rather than 1e18) is that it ensures negligible precision loss close to the
 * scale boundary: when P is at its minimum value of 1e9, the relative precision loss in P due to floor division is only on the
 * order of 1e-9.
 *
 * --- EPOCHS ---
 *
 * Whenever a liquidation fully empties the Stability Pool, all deposits should become 0. However, setting P to 0 would make P be 0
 * forever, and break all future reward calculations.
 *
 * So, every time the Stability Pool is emptied by a liquidation, we reset P = 1 and currentScale = 0, and increment the currentEpoch by 1.
 *
 * --- TRACKING DEPOSIT OVER SCALE CHANGES AND EPOCHS ---
 *
 * When a deposit is made, it gets snapshots of the currentEpoch and the currentScale.
 *
 * When calculating a compounded deposit, we compare the current epoch to the deposit's epoch snapshot. If the current epoch is newer,
 * then the deposit was present during a pool-emptying liquidation, and necessarily has been depleted to 0.
 *
 * Otherwise, we then compare the current scale to the deposit's scale snapshot. If they're equal, the compounded deposit is given by d_t * P/P_t.
 * If it spans one scale change, it is given by d_t * P/(P_t * 1e9). If it spans more than one scale change, we define the compounded deposit
 * as 0, since it is now less than 1e-9'th of its initial value (e.g. a deposit of 1 billion USDE has depleted to < 1 USDE).
 *
 *
 *  --- TRACKING DEPOSITOR'S ETH/wrapperETH GAIN OVER SCALE CHANGES AND EPOCHS ---
 *
 * In the current epoch, the latest value of S is stored upon each scale change, and the mapping (scale -> S) is stored for each epoch.
 *
 * This allows us to calculate a deposit's accumulated ETH/wrapperETH gain, during the epoch in which the deposit was non-zero and earned ETH.
 *
 * We calculate the depositor's accumulated ETH/wrapperETH gain for the scale at which they made the deposit, using the ETH gain formula:
 * e_1 = d_t * (S - S_t) / P_t
 *
 * and also for scale after, taking care to divide the latter by a factor of 1e9:
 * e_2 = d_t * S / (P_t * 1e9)
 *
 * The gain in the second scale will be full, as the starting point was in the previous scale, thus no need to subtract anything.
 * The deposit therefore was present for reward events from the beginning of that second scale.
 *
 *        S_i-S_t + S_{i+1}
 *      .<--------.------------>
 *      .         .
 *      . S_i     .   S_{i+1}
 *   <--.-------->.<----------->
 *   S_t.         .
 *   <->.         .
 *      t         .
 *  |---+---------|-------------|-----...
 *         i            i+1
 *
 * The sum of (e_1 + e_2) captures the depositor's total accumulated ETH/wrapperETH gain, handling the case where their
 * deposit spanned one scale change. We only care about gains across one scale change, since the compounded
 * deposit is defined as being 0 once it has spanned more than one scale change.
 *
 *
 * --- UPDATING P WHEN A LIQUIDATION OCCURS ---
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH/wrapperETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 *
 * --- GAIN ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An GAIN issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued GAIN in proportion to the deposit as a share of total deposits. The GAIN earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 *
 * We use the same mathematical product-sum approach to track GAIN gains for depositors, where 'G' is the sum corresponding to GAIN gains.
 * The product P (and snapshot P_t) is re-used, as the ratio P/P_t tracks a deposit's depletion due to liquidations.
 *
 */
contract StabilityPool is
    ERDBase,
    OwnableUpgradeable,
    IStabilityPool,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public constant NAME = "StabilityPool";

    IBorrowerOperations public borrowerOperations;

    ITroveManager public troveManager;

    // Needed to check if there are pending liquidations
    ISortedTroves public sortedTroves;

    ICommunityIssuance public communityIssuance;

    address internal troveManagerLiquidationsAddress;

    IWETH public WETH;

    // Tracker for USDE held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
    uint256 internal totalUSDEDeposits;

    mapping(address => Deposit) public deposits; // depositor address -> Deposit struct
    mapping(address => Snapshots) public depositSnapshots; // depositor address -> snapshots struct

    mapping(address => FrontEnd) public frontEnds; // front end address -> FrontEnd struct
    mapping(address => uint256) public frontEndStakes; // front end address -> last recorded total deposits, tagged with that front end
    mapping(address => Snapshots) public frontEndSnapshots; // front end address -> snapshots struct

    /*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
     * after a series of liquidations have occurred, each of which cancel some USDE debt with the deposit.
     *
     * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
     * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
     */
    uint256 public P;

    uint256 public constant SCALE_FACTOR = 1e9;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;

    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;

    /* Collateral Gain sum 'S': During its lifetime, each deposit d_t earns an collateral gain of ( d_t * [S - S_t] )/P_t, where S_t
     * is the depositor's snapshot of S taken at the time t when the deposit was made.
     *
     * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
     *
     * - The inner mapping records the sum S at different scales
     * - The outer mapping records the (scale => sum) mappings, for different epochs.
     */
    mapping(address => mapping(uint128 => mapping(uint128 => uint256)))
        public epochToScaleToSum;

    /*
     * Similarly, the sum 'G' is used to calculate GAIN gains. During it's lifetime, each deposit d_t earns a GAIN gain of
     *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
     *
     *  GAIN reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
     *  In each case, the GAIN reward is issued (i.e. G is updated), before other state changes are made.
     */
    mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

    // Error tracker for the error correction in the GAIN issuance calculation
    uint256 public lastGainError;
    // Error trackers for the error correction in the offset calculation
    mapping(address => uint256) public lastCollError_Offset;
    uint256 public lastUSDELossError_Offset;

    bool internal paused;

    modifier whenNotPaused() {
        if (paused) {
            revert Errors.ProtocolPaused();
        }
        _;
    }

    // --- Contract setters ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        P = DECIMAL_PRECISION;
    }

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _collateralManagerAddress,
        address _troveManagerLiquidationsAddress,
        address _activePoolAddress,
        address _usdeTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress,
        address _wethAddress
    ) external override onlyOwner {
        _requireIsContract(_borrowerOperationsAddress);
        _requireIsContract(_troveManagerAddress);
        _requireIsContract(_collateralManagerAddress);
        _requireIsContract(_troveManagerLiquidationsAddress);
        _requireIsContract(_activePoolAddress);
        _requireIsContract(_usdeTokenAddress);
        _requireIsContract(_sortedTrovesAddress);
        _requireIsContract(_priceFeedAddress);
        _requireIsContract(_communityIssuanceAddress);
        _requireIsContract(_wethAddress);

        borrowerOperations = IBorrowerOperations(_borrowerOperationsAddress);
        troveManager = ITroveManager(_troveManagerAddress);
        collateralManager = ICollateralManager(_collateralManagerAddress);
        troveManagerLiquidationsAddress = _troveManagerLiquidationsAddress;
        activePool = IActivePool(_activePoolAddress);
        usdeToken = IUSDEToken(_usdeTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
        WETH = IWETH(_wethAddress);
        WETH.approve(_borrowerOperationsAddress, type(uint256).max);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit CollateralManagerAddressChanged(_collateralManagerAddress);
        emit TroveManagerLiquidationsAddressChanged(
            _troveManagerLiquidationsAddress
        );
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit USDETokenAddressChanged(_usdeTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit CommunityIssuanceAddressChanged(_communityIssuanceAddress);
        emit WETHAddressChanged(_wethAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---

    function getTotalCollateral()
        public
        view
        override
        returns (
            uint256 total,
            address[] memory collaterals,
            uint256[] memory amounts
        )
    {
        collaterals = collateralManager.getCollateralSupport();
        uint256 collLen = collaterals.length;
        amounts = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            amounts[i] = IERC20Upgradeable(collaterals[i]).balanceOf(
                address(this)
            );
            total = total.add(amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getCollateralAmount(
        address _collateral
    ) external view override returns (uint256) {
        return IERC20Upgradeable(_collateral).balanceOf(address(this));
    }

    function getTotalUSDEDeposits() external view override returns (uint256) {
        return totalUSDEDeposits;
    }

    // --- External Depositor Functions ---

    /*  provideToSP():
     *
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains collateral(ETH/wrapperETH) to depositor
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(
        uint256 _amount,
        address _frontEndTag
    ) external override whenNotPaused nonReentrant {
        _requireFrontEndIsRegisteredOrZero(_frontEndTag);
        _requireFrontEndNotRegistered(msg.sender);
        _requireNonZeroAmount(_amount);

        uint256 initialDeposit = deposits[msg.sender].initialValue;

        ICommunityIssuance communityIssuanceCached = communityIssuance;
        // do nothing
        _trigger(communityIssuanceCached);

        if (initialDeposit == 0) {
            _setFrontEndTag(msg.sender, _frontEndTag);
        }
        (
            address[] memory collaterals,
            uint256[] memory depositorCollateralGains
        ) = getDepositorCollateralGain(msg.sender);
        uint256 compoundedUSDEDeposit = getCompoundedUSDEDeposit(msg.sender);
        uint256 USDELoss = initialDeposit.sub(compoundedUSDEDeposit); // Needed only for event log

        // First pay out any gains or maybe nothing
        address frontEnd = deposits[msg.sender].frontEndTag;
        _payOutGains(communityIssuanceCached, msg.sender, frontEnd);

        // Update front end stake
        uint256 compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint256 newFrontEndStake = compoundedFrontEndStake.add(_amount);
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, msg.sender);

        _sendUSDEtoStabilityPool(msg.sender, _amount);

        uint256 newDeposit = compoundedUSDEDeposit.add(_amount);
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit CollGainWithdrawn(msg.sender, depositorCollateralGains, USDELoss); // USDE Loss required for event log

        _sendCollateralGainToDepositor(collaterals, depositorCollateralGains);
    }

    /*  withdrawFromSP():
     *
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains collateral(ETH/wrapperETH) to depositor
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(
        uint256 _amount
    ) external override whenNotPaused nonReentrant {
        if (_amount != 0) {
            _requireNoUnderCollateralizedTroves();
        }
        uint256 initialDeposit = deposits[msg.sender].initialValue;
        _requireUserHasDeposit(initialDeposit);

        ICommunityIssuance communityIssuanceCached = communityIssuance;
        // do nothing
        _trigger(communityIssuanceCached);

        (
            address[] memory collaterals,
            uint256[] memory depositorCollateralGains
        ) = getDepositorCollateralGain(msg.sender);
        uint256 compoundedUSDEDeposit = getCompoundedUSDEDeposit(msg.sender);
        uint256 USDEtoWithdraw = ERDMath._min(_amount, compoundedUSDEDeposit);
        uint256 USDELoss = initialDeposit.sub(compoundedUSDEDeposit); // Needed only for event log

        // First pay out any gains or maybe nothing
        address frontEnd = deposits[msg.sender].frontEndTag;
        _payOutGains(communityIssuanceCached, msg.sender, frontEnd);
        // Update front end stake
        uint256 compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint256 newFrontEndStake = compoundedFrontEndStake.sub(USDEtoWithdraw);
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, msg.sender);
        _sendUSDEToDepositor(msg.sender, USDEtoWithdraw);

        // Update deposit
        uint256 newDeposit = compoundedUSDEDeposit.sub(USDEtoWithdraw);
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit CollGainWithdrawn(msg.sender, depositorCollateralGains, USDELoss); // USDE Loss required for event log

        _sendCollateralGainToDepositor(collaterals, depositorCollateralGains);
    }

    /* withdrawCollateralGainToTrove:
     * - Triggers a gain issuance, based on time passed since the last issuance. The gain issuance is shared between *all* depositors and front ends
     * - Sends all depositor's gain to  depositor
     * - Sends all tagged front end's gain to the tagged front end
     * - Transfers the depositor's entire collateral gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake */
    function withdrawCollateralGainToTrove(
        address _upperHint,
        address _lowerHint
    ) external override whenNotPaused nonReentrant {
        uint256 initialDeposit = deposits[msg.sender].initialValue;
        _requireUserHasDeposit(initialDeposit);
        _requireUserHasTrove(msg.sender);
        (
            address[] memory collaterals,
            uint256[] memory depositorCollateralGains
        ) = _requireUserHasCollGain(msg.sender);

        ICommunityIssuance communityIssuanceCached = communityIssuance;
        // do nothing
        _trigger(communityIssuanceCached);

        uint256 compoundedUSDEDeposit = getCompoundedUSDEDeposit(msg.sender);
        uint256 USDELoss = initialDeposit.sub(compoundedUSDEDeposit); // Needed only for event log

        // First pay out any gains or maybe nothing
        address frontEnd = deposits[msg.sender].frontEndTag;
        _payOutGains(communityIssuanceCached, msg.sender, frontEnd);

        // Update front end stake
        uint256 compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint256 newFrontEndStake = compoundedFrontEndStake;
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, msg.sender);

        _updateDepositAndSnapshots(msg.sender, compoundedUSDEDeposit);

        /* Emit events before transferring collateral gain to Trove.
         This lets the event log make more sense (i.e. so it appears that first the collateral gain is withdrawn
        and then it is deposited into the Trove, not the other way around). */
        emit CollGainWithdrawn(msg.sender, depositorCollateralGains, USDELoss);
        emit UserDepositChanged(msg.sender, compoundedUSDEDeposit);

        borrowerOperations.moveCollGainToTrove(
            msg.sender,
            collaterals,
            depositorCollateralGains,
            _upperHint,
            _lowerHint
        );

        emit CollateralsSent(msg.sender, depositorCollateralGains);
    }

    // --- gain issuance functions ---

    function _trigger(ICommunityIssuance _communityIssuance) internal {
        uint256 issuance = _communityIssuance.issue();
        _updateG(issuance);
    }

    function _updateG(uint256 _issuance) internal {
        uint256 totalUSDE = totalUSDEDeposits; // cached to save an SLOAD
        /*
         * When total deposits is 0, G is not updated. In this case, the gain issued can not be obtained by later
         * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
         *
         */
        if (totalUSDE == 0 || _issuance == 0) {
            return;
        }

        uint256 gainPerUnitStaked;
        gainPerUnitStaked = _computeGainPerUnitStaked(_issuance, totalUSDE);

        uint256 marginalGain = gainPerUnitStaked.mul(P);
        epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[
            currentEpoch
        ][currentScale].add(marginalGain);

        emit G_Updated(
            epochToScaleToG[currentEpoch][currentScale],
            currentEpoch,
            currentScale
        );
    }

    function _computeGainPerUnitStaked(
        uint256 _issuance,
        uint256 _totalUSDEDeposits
    ) internal returns (uint256) {
        /*
         * Calculate the Gain-per-unit staked.  Division uses a "feedback" error correction, to keep the
         * cumulative error low in the running total G:
         *
         * 1) Form a numerator which compensates for the floor division error that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratio.
         * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
         * 4) Store this error for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint256 gainNumerator = _issuance.mul(DECIMAL_PRECISION).add(
            lastGainError
        );

        uint256 gainPerUnitStaked = gainNumerator.div(_totalUSDEDeposits);
        lastGainError = gainNumerator.sub(
            gainPerUnitStaked.mul(_totalUSDEDeposits)
        );

        return gainPerUnitStaked;
    }

    // --- Liquidation functions ---

    /*
     * Cancels out the specified debt against the USDE contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH/wrapperETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(
        uint256 _debtToOffset,
        address[] memory _collaterals,
        uint256[] memory _collToAdd
    ) external override whenNotPaused nonReentrant {
        _requireCallerIsTroveML();
        uint256 totalUSDE = totalUSDEDeposits; // cached to save an SLOAD
        if (totalUSDE == 0 || _debtToOffset == 0) {
            return;
        }

        _trigger(communityIssuance);

        (
            uint256[] memory collGainPerUnitStakeds,
            uint256 USDELossPerUnitStaked
        ) = _computeRewardsPerUnitStaked(
                _collaterals,
                _collToAdd,
                _debtToOffset,
                totalUSDE
            );

        _updateRewardSumAndProduct(
            _collaterals,
            collGainPerUnitStakeds,
            USDELossPerUnitStaked
        ); // updates S and P

        _moveOffsetCollAndDebt(_collaterals, _collToAdd, _debtToOffset);
    }

    function setPause(bool val) external override onlyOwner {
        paused = val;
        if (paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }

    function authorizeBorrowerOperations(
        address _collateral,
        uint256 _value
    ) external onlyOwner {
        if (!collateralManager.getIsActive(_collateral)) {
            revert Errors.CM_CollNotActive();
        }
        IERC20Upgradeable(_collateral).safeIncreaseAllowance(
            address(borrowerOperations),
            _value
        );
    }

    function unauthorizeBorrowerOperations(
        address _collateral,
        uint256 _value
    ) external onlyOwner {
        if (!collateralManager.getIsSupport(_collateral)) {
            revert Errors.CM_CollNotSupported();
        }
        IERC20Upgradeable(_collateral).safeDecreaseAllowance(
            address(borrowerOperations),
            _value
        );
    }

    // --- Offset helper functions ---

    function _computeRewardsPerUnitStaked(
        address[] memory _collaterals,
        uint256[] memory _collToAdd,
        uint256 _debtToOffset,
        uint256 _totalUSDEDeposits
    )
        internal
        returns (
            uint256[] memory collGainPerUnitStakeds,
            uint256 USDELossPerUnitStaked
        )
    {
        /*
         * Compute the USDE and ETH/wrapperETH rewards. Uses a "feedback" error correction, to keep
         * the cumulative error in the P and S state variables low:
         *
         * 1) Form numerators which compensate for the floor division errors that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratios.
         * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
         * 4) Store these errors for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint256 collateralsLen = _collaterals.length;
        uint256[] memory collNumerators = new uint256[](collateralsLen);
        collGainPerUnitStakeds = new uint256[](collateralsLen);
        uint256 currentP = P;

        if (_debtToOffset > _totalUSDEDeposits) {
            revert Errors.SP_BadDebtOffset();
        }
        if (_debtToOffset == _totalUSDEDeposits) {
            USDELossPerUnitStaked = DECIMAL_PRECISION; // When the Pool depletes to 0, so does each deposit
            lastUSDELossError_Offset = 0;
        } else {
            uint256 USDELossNumerator = _debtToOffset
                .mul(DECIMAL_PRECISION)
                .sub(lastUSDELossError_Offset);
            /*
             * Add 1 to make error in quotient positive. We want "slightly too much" USDE loss,
             * which ensures the error in any given compoundedUSDEDeposit favors the Stability Pool.
             */
            USDELossPerUnitStaked = (USDELossNumerator.div(_totalUSDEDeposits))
                .add(1);
            lastUSDELossError_Offset = (
                USDELossPerUnitStaked.mul(_totalUSDEDeposits)
            ).sub(USDELossNumerator);
        }

        address collateral;
        uint256[] memory shares = collateralManager.getShares(
            _collaterals,
            _collToAdd
        );
        uint256 i = 0;
        for (; i < collateralsLen; ) {
            collateral = _collaterals[i];
            collNumerators[i] = shares[i].mul(DECIMAL_PRECISION).add(
                lastCollError_Offset[collateral]
            );

            collGainPerUnitStakeds[i] = collNumerators[i].mul(currentP).div(
                _totalUSDEDeposits
            );

            lastCollError_Offset[collateral] = collNumerators[i].sub(
                collGainPerUnitStakeds[i].mul(_totalUSDEDeposits).div(currentP)
            );
            unchecked {
                ++i;
            }
        }
    }

    // Update the Stability Pool reward sum S and product P
    function _updateRewardSumAndProduct(
        address[] memory _collaterals,
        uint256[] memory _collGainPerUnitStakeds,
        uint256 _USDELossPerUnitStaked
    ) internal {
        uint256 currentP = P;
        uint256 newP;

        if (_USDELossPerUnitStaked > DECIMAL_PRECISION) {
            revert Errors.SP_USDELossGreaterThanOne();
        }
        /*
         * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool USDE in the liquidation.
         * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - USDELossPerUnitStaked)
         */
        uint256 newProductFactor = uint256(DECIMAL_PRECISION).sub(
            _USDELossPerUnitStaked
        );

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;

        /*
         * Calculate the new S first, before we update P.
         * The collateral gain for any given depositor from a liquidation depends on the value of their deposit
         * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
         *
         * Since S corresponds to collateral gain, and P to deposit loss, we update S first.
         */
        uint256 collateralsLen = _collaterals.length;
        uint256[] memory currentSs = new uint256[](collateralsLen);
        uint256 i = 0;
        for (; i < collateralsLen; ) {
            address collateral = _collaterals[i];
            uint256 currentSColl = epochToScaleToSum[collateral][
                currentEpochCached
            ][currentScaleCached];
            uint256 newSColl = currentSColl.add(_collGainPerUnitStakeds[i]);

            epochToScaleToSum[collateral][currentEpochCached][
                currentScaleCached
            ] = newSColl;
            currentSs[i] = newSColl;
            unchecked {
                ++i;
            }
        }
        emit S_Updated(currentSs, currentEpochCached, currentScaleCached);

        // If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
        if (newProductFactor == 0) {
            currentEpoch = currentEpochCached + 1;
            emit EpochUpdated(currentEpoch);
            currentScale = 0;
            emit ScaleUpdated(currentScale);
            newP = DECIMAL_PRECISION;

            // If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
        } else if (
            currentP.mul(newProductFactor).div(DECIMAL_PRECISION) < SCALE_FACTOR
        ) {
            newP = currentP.mul(newProductFactor).mul(SCALE_FACTOR).div(
                DECIMAL_PRECISION
            );
            currentScale = currentScaleCached + 1;
            emit ScaleUpdated(currentScale);
        } else {
            newP = currentP.mul(newProductFactor).div(DECIMAL_PRECISION);
        }

        if (newP == 0) {
            revert Errors.SP_ZeroValue();
        }
        P = newP;

        emit P_Updated(newP);
    }

    function _moveOffsetCollAndDebt(
        address[] memory _collaterals,
        uint256[] memory _collToAdd,
        uint256 _debtToOffset
    ) internal {
        IActivePool activePoolCached = activePool;

        // Cancel the liquidated USDE debt with the USDE in the stability pool
        activePoolCached.decreaseUSDEDebt(_debtToOffset);
        _decreaseUSDE(_debtToOffset);

        // Burn the debt that was successfully offset
        usdeToken.burn(address(this), _debtToOffset);

        activePoolCached.sendCollateral(
            address(this),
            _collaterals,
            _collToAdd
        );
    }

    function _decreaseUSDE(uint256 _amount) internal {
        uint256 newTotalUSDEDeposits = totalUSDEDeposits.sub(_amount);
        totalUSDEDeposits = newTotalUSDEDeposits;
        emit StabilityPoolUSDEBalanceUpdated(newTotalUSDEDeposits);
    }

    // --- Reward calculator functions for depositor and front end ---

    /* Calculates the collateral gain earned by the deposit since its last snapshots were taken.
     * Given by the formula:  E = d0 * (S - S(0))/P(0)
     * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
     * d0 is the last recorded deposit value.
     */
    function getDepositorCollateralGain(
        address _depositor
    ) public view override returns (address[] memory, uint256[] memory) {
        uint256 initialDeposit = deposits[_depositor].initialValue;

        if (initialDeposit == 0) {
            return (new address[](0), new uint256[](0));
        }

        Snapshots storage snapshots = depositSnapshots[_depositor];

        return _calculateGains(initialDeposit, snapshots);
    }

    function _calculateGains(
        uint256 initialDeposit,
        Snapshots storage snapshots
    )
        internal
        view
        returns (address[] memory collaterals, uint256[] memory gains)
    {
        collaterals = collateralManager.getCollateralSupport();
        uint256 collLen = collaterals.length;
        uint256[] memory shares = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            shares[i] = _getCollateralGainFromSnapshots(
                initialDeposit,
                snapshots,
                collaterals[i]
            );
            unchecked {
                ++i;
            }
        }
        gains = collateralManager.getAmounts(collaterals, shares);
    }

    function _getCollateralGainFromSnapshots(
        uint256 _initialDeposit,
        Snapshots storage snapshots,
        address _collateral
    ) internal view returns (uint256) {
        uint256 initialDeposit = _initialDeposit;
        address collateral = _collateral;
        /*
         * Grab the sum 'S' from the epoch at which the stake was made. The collateral gain may span up to one scale change.
         * If it does, the second portion of the collateral gain is scaled by 1e9.
         * If the gain spans no scale change, the second portion will be 0.
         */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint256 S_Snapshot = snapshots.S[collateral];
        uint256 P_Snapshot = snapshots.P;

        uint256 firstPortion = epochToScaleToSum[collateral][epochSnapshot][
            scaleSnapshot
        ].sub(S_Snapshot);
        uint256 secondPortion = epochToScaleToSum[collateral][epochSnapshot][
            scaleSnapshot + 1
        ].div(SCALE_FACTOR);

        return
            initialDeposit
                .mul(firstPortion.add(secondPortion))
                .div(P_Snapshot)
                .div(DECIMAL_PRECISION);
    }

    /*
     * Calculate the gain earned by a deposit since its last snapshots were taken.
     * Given by the formula:  Gain = d0 * (G - G(0))/P(0)
     * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
     * d0 is the last recorded deposit value.
     */
    function getDepositorGain(
        address _depositor
    ) public view override returns (uint256) {
        uint256 initialDeposit = deposits[_depositor].initialValue;
        if (initialDeposit == 0) {
            return 0;
        }

        address frontEndTag = deposits[_depositor].frontEndTag;

        /*
         * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
         * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
         * which they made their deposit.
         */
        uint256 kickbackRate = frontEndTag == address(0)
            ? DECIMAL_PRECISION
            : frontEnds[frontEndTag].kickbackRate;

        Snapshots storage snapshots = depositSnapshots[_depositor];

        uint256 gain = kickbackRate
            .mul(_getGainFromSnapshots(initialDeposit, snapshots))
            .div(DECIMAL_PRECISION);

        return gain;
    }

    /*
     * Return the gain earned by the front end. Given by the formula:  E = D0 * (G - G(0))/P(0)
     * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
     *
     * D0 is the last recorded value of the front end's total tagged deposits.
     */
    function getFrontEndGain(
        address _frontEnd
    ) public view override returns (uint256) {
        uint256 frontEndStake = frontEndStakes[_frontEnd];
        if (frontEndStake == 0) {
            return 0;
        }

        uint256 kickbackRate = frontEnds[_frontEnd].kickbackRate;
        uint256 frontEndShare = uint256(DECIMAL_PRECISION).sub(kickbackRate);

        Snapshots storage snapshots = frontEndSnapshots[_frontEnd];

        uint256 gain = frontEndShare
            .mul(_getGainFromSnapshots(frontEndStake, snapshots))
            .div(DECIMAL_PRECISION);
        return gain;
    }

    function _getGainFromSnapshots(
        uint256 initialStake,
        Snapshots storage snapshots
    ) internal view returns (uint256) {
        /*
         * Grab the sum 'G' from the epoch at which the stake was made. The gain may span up to one scale change.
         * If it does, the second portion of the gain is scaled by 1e9.
         * If the gain spans no scale change, the second portion will be 0.
         */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint256 G_Snapshot = snapshots.G;
        uint256 P_Snapshot = snapshots.P;

        uint256 firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot]
            .sub(G_Snapshot);
        uint256 secondPortion = epochToScaleToG[epochSnapshot][
            scaleSnapshot + 1
        ].div(SCALE_FACTOR);

        uint256 gain = initialStake
            .mul(firstPortion.add(secondPortion))
            .div(P_Snapshot)
            .div(DECIMAL_PRECISION);

        return gain;
    }

    // --- Compounded deposit and compounded front end stake ---

    /*
     * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
     * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
     */
    function getCompoundedUSDEDeposit(
        address _depositor
    ) public view override returns (uint256) {
        uint256 initialDeposit = deposits[_depositor].initialValue;
        if (initialDeposit == 0) {
            return 0;
        }

        Snapshots storage snapshots = depositSnapshots[_depositor];

        uint256 compoundedDeposit = _getCompoundedStakeFromSnapshots(
            initialDeposit,
            snapshots
        );
        return compoundedDeposit;
    }

    /*
     * Return the front end's compounded stake. Given by the formula:  D = D0 * P/P(0)
     * where P(0) is the depositor's snapshot of the product P, taken at the last time
     * when one of the front end's tagged deposits updated their deposit.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(
        address _frontEnd
    ) public view override returns (uint256) {
        uint256 frontEndStake = frontEndStakes[_frontEnd];
        if (frontEndStake == 0) {
            return 0;
        }

        Snapshots storage snapshots = frontEndSnapshots[_frontEnd];

        uint256 compoundedFrontEndStake = _getCompoundedStakeFromSnapshots(
            frontEndStake,
            snapshots
        );
        return compoundedFrontEndStake;
    }

    // Internal function, used to calculcate compounded deposits and compounded front end stakes.
    function _getCompoundedStakeFromSnapshots(
        uint256 initialStake,
        Snapshots storage snapshots
    ) internal view returns (uint256) {
        uint256 snapshot_P = snapshots.P;
        uint128 scaleSnapshot = snapshots.scale;
        uint128 epochSnapshot = snapshots.epoch;

        // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
        if (epochSnapshot < currentEpoch) {
            return 0;
        }

        uint256 compoundedStake;
        uint128 scaleDiff = currentScale - scaleSnapshot;

        /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
         * account for it. If more than one scale change was made, then the stake has decreased by a factor of
         * at least 1e-9 -- so return 0.
         */
        if (scaleDiff == 0) {
            compoundedStake = initialStake.mul(P).div(snapshot_P);
        } else if (scaleDiff == 1) {
            compoundedStake = initialStake.mul(P).div(snapshot_P).div(
                SCALE_FACTOR
            );
        } else {
            // if scaleDiff >= 2
            compoundedStake = 0;
        }

        if (compoundedStake > totalUSDEDeposits) {
            compoundedStake = totalUSDEDeposits;
        }

        /*
         * If compounded deposit is less than a billionth of the initial deposit, return 0.
         *
         * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
         * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
         * than it's theoretical value.
         *
         * Thus it's unclear whether this line is still really needed.
         */
        if (compoundedStake < initialStake.div(1e9)) {
            return 0;
        }

        return compoundedStake;
    }

    // --- Sender functions for USDE deposit, collateral gains and other gains ---

    // Transfer the USDE tokens from the user to the Stability Pool's address, and update its recorded USDE
    function _sendUSDEtoStabilityPool(
        address _address,
        uint256 _amount
    ) internal {
        usdeToken.sendToPool(_address, address(this), _amount);
        uint256 newTotalUSDEDeposits = totalUSDEDeposits.add(_amount);
        totalUSDEDeposits = newTotalUSDEDeposits;
        emit StabilityPoolUSDEBalanceUpdated(newTotalUSDEDeposits);
    }

    function _sendCollateralGainToDepositor(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) internal {
        uint256 collateralLen = _collaterals.length;
        if (collateralLen != _amounts.length) {
            revert Errors.LengthMismatch();
        }

        uint256 amount;
        address collateral;
        bool hasETH;
        uint256 ETHAmount;
        uint256 i = 0;
        for (; i < collateralLen; ) {
            collateral = _collaterals[i];
            amount = _amounts[i];
            if (amount != 0) {
                if (collateral != address(WETH)) {
                    IERC20Upgradeable(collateral).safeTransfer(
                        msg.sender,
                        amount
                    );
                } else {
                    hasETH = true;
                    ETHAmount = amount;
                }
                emit StabilityPoolCollBalanceUpdated(
                    collateral,
                    IERC20Upgradeable(collateral).balanceOf(address(this))
                );
                emit CollateralSent(msg.sender, collateral, amount);
            }
            unchecked {
                ++i;
            }
        }
        if (hasETH) {
            WETH.withdraw(ETHAmount);
            (bool success, ) = msg.sender.call{value: ETHAmount}("");
            if (!success) {
                revert Errors.SendETHFailed();
            }
            emit StabilityPoolCollBalanceUpdated(
                address(WETH),
                IERC20Upgradeable(address(WETH)).balanceOf(address(this))
            );
            emit CollateralSent(msg.sender, address(WETH), ETHAmount);
        }
    }

    // Send USDE to user and decrease USDE in Pool
    function _sendUSDEToDepositor(
        address _depositor,
        uint256 USDEWithdrawal
    ) internal {
        if (USDEWithdrawal == 0) {
            return;
        }

        usdeToken.returnFromPool(address(this), _depositor, USDEWithdrawal);
        _decreaseUSDE(USDEWithdrawal);
    }

    // --- External Front End functions ---

    // Front end makes a one-time selection of kickback rate upon registering
    function registerFrontEnd(uint256 _kickbackRate) external override {
        _requireFrontEndNotRegistered(msg.sender);
        _requireUserHasNoDeposit(msg.sender);
        _requireValidKickbackRate(_kickbackRate);

        frontEnds[msg.sender].kickbackRate = _kickbackRate;
        frontEnds[msg.sender].registered = true;

        emit FrontEndRegistered(msg.sender, _kickbackRate);
    }

    // --- Stability Pool Deposit Functionality ---

    function _setFrontEndTag(
        address _depositor,
        address _frontEndTag
    ) internal {
        deposits[_depositor].frontEndTag = _frontEndTag;
        emit FrontEndTagSet(_depositor, _frontEndTag);
    }

    function _updateDepositAndSnapshots(
        address _depositor,
        uint256 _newValue
    ) internal {
        address[] memory collaterals = collateralManager.getCollateralSupport();
        address depositor = _depositor;
        deposits[depositor].initialValue = _newValue;
        uint256 collateralLen = collaterals.length;
        uint256[] memory currentSs = new uint256[](collateralLen);
        uint256 i = 0;
        if (_newValue == 0) {
            delete deposits[depositor].frontEndTag;
            for (; i < collateralLen; ) {
                depositSnapshots[depositor].S[collaterals[i]] = 0;
                unchecked {
                    ++i;
                }
            }
            depositSnapshots[depositor].P = 0;
            depositSnapshots[depositor].G = 0;
            depositSnapshots[depositor].epoch = 0;
            depositSnapshots[depositor].scale = 0;
            emit DepositSnapshotUpdated(depositor, 0, new uint256[](0), 0);
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint256 currentP = P;

        // Get S and G for the current epoch and current scale
        address collateral;
        uint256 currentSColl;
        for (; i < collateralLen; ) {
            collateral = collaterals[i];
            currentSColl = epochToScaleToSum[collateral][currentEpochCached][
                currentScaleCached
            ];
            depositSnapshots[_depositor].S[collateral] = currentSColl;
            currentSs[i] = currentSColl;
            unchecked {
                ++i;
            }
        }
        uint256 currentG = epochToScaleToG[currentEpochCached][
            currentScaleCached
        ];

        // Record new snapshots of the latest running product P, sum S, and sum G, for the depositor
        depositSnapshots[depositor].P = currentP;
        depositSnapshots[depositor].G = currentG;
        depositSnapshots[depositor].scale = currentScaleCached;
        depositSnapshots[depositor].epoch = currentEpochCached;

        emit DepositSnapshotUpdated(depositor, currentP, currentSs, currentG);
    }

    function _updateFrontEndStakeAndSnapshots(
        address _frontEnd,
        uint256 _newValue
    ) internal {
        frontEndStakes[_frontEnd] = _newValue;

        if (_newValue == 0) {
            delete frontEndSnapshots[_frontEnd];
            emit FrontEndSnapshotUpdated(_frontEnd, 0, 0);
            return;
        }

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint256 currentP = P;

        // Get G for the current epoch and current scale
        uint256 currentG = epochToScaleToG[currentEpochCached][
            currentScaleCached
        ];

        // Record new snapshots of the latest running product P and sum G for the front end
        frontEndSnapshots[_frontEnd].P = currentP;
        frontEndSnapshots[_frontEnd].G = currentG;
        frontEndSnapshots[_frontEnd].scale = currentScaleCached;
        frontEndSnapshots[_frontEnd].epoch = currentEpochCached;

        emit FrontEndSnapshotUpdated(_frontEnd, currentP, currentG);
    }

    function _payOutGains(
        ICommunityIssuance _communityIssuance,
        address _depositor,
        address _frontEnd
    ) internal {
        // Pay out front end's other gain
        if (_frontEnd != address(0)) {
            uint256 frontEndGain = getFrontEndGain(_frontEnd);
            _communityIssuance.trigger(_frontEnd, frontEndGain);
            emit GainPaidToFrontEnd(_frontEnd, frontEndGain);
        }

        // Pay out depositor's gain
        uint256 depositorGain = getDepositorGain(_depositor);
        _communityIssuance.trigger(_depositor, depositorGain);
        emit GainPaidToDepositor(_depositor, depositorGain);
    }

    // Gets reward snapshot S for certain collateral and depositor.
    function getDepositSnapshotS(
        address _depositor,
        address _collateral
    ) external view override returns (uint256) {
        return depositSnapshots[_depositor].S[_collateral];
    }

    function approveBorrowerOperations() external {
        WETH.approve(address(borrowerOperations), type(uint256).max);
    }

    // --- 'require' functions ---

    function _requireIsContract(address _contract) internal view {
        if (!_contract.isContract()) {
            revert Errors.NotContract();
        }
    }

    function _requireCallerIsActivePool() internal view {
        if (msg.sender != address(activePool)) {
            revert Errors.Caller_NotAP();
        }
    }

    function _requireCallerIsTroveManager() internal view {
        if (msg.sender != address(troveManager)) {
            revert Errors.Caller_NotTM();
        }
    }

    function _requireCallerIsTroveML() internal view {
        if (msg.sender != troveManagerLiquidationsAddress) {
            revert Errors.Caller_NotTML();
        }
    }

    function _requireNoUnderCollateralizedTroves() internal {
        uint256 price = priceFeed.fetchPrice();
        collateralManager.priceUpdate();
        address lowestTrove = sortedTroves.getLast();
        uint256 ICR = troveManager.getCurrentICR(lowestTrove, price);
        if (ICR < collateralManager.getMCR()) {
            revert Errors.SP_WithdrawWithICRLessThanMCR();
        }
    }

    function _requireUserHasDeposit(uint256 _initialDeposit) internal pure {
        if (_initialDeposit == 0) {
            revert Errors.SP_NoDepositBefore();
        }
    }

    function _requireUserHasNoDeposit(address _address) internal view {
        uint256 initialDeposit = deposits[_address].initialValue;
        if (initialDeposit > 0) {
            revert Errors.SP_HadDeposit();
        }
    }

    function _requireNonZeroAmount(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert Errors.SP_ZeroValue();
        }
    }

    function _requireUserHasTrove(address _depositor) internal view {
        if (
            troveManager.getTroveStatus(_depositor) != DataTypes.Status.active
        ) {
            revert Errors.SP_CallerTroveNotActive();
        }
    }

    function _requireUserHasCollGain(
        address _depositor
    )
        internal
        view
        returns (address[] memory collaterals, uint256[] memory collateralGains)
    {
        (collaterals, collateralGains) = getDepositorCollateralGain(_depositor);
        if (!ERDMath._arrayIsNonzero(collateralGains)) {
            revert Errors.SP_ZeroGain();
        }
    }

    function _requireFrontEndNotRegistered(address _address) internal view {
        if (frontEnds[_address].registered) {
            revert Errors.SP_AlreadyRegistered();
        }
    }

    function _requireFrontEndIsRegisteredOrZero(
        address _address
    ) internal view {
        if (!(frontEnds[_address].registered || _address == address(0))) {
            revert Errors.SP_MustRegisteredOrZeroAddress();
        }
    }

    function _requireValidKickbackRate(uint256 _kickbackRate) internal pure {
        if (_kickbackRate > DECIMAL_PRECISION) {
            revert Errors.SP_BadKickbackRate();
        }
    }

    // --- Fallback function ---

    receive() external payable {}
}
