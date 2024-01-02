// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ITroveManager.sol";
import "./ITroveManagerLiquidations.sol";
import "./ITroveManagerRedemptions.sol";
import "./ICollateralManager.sol";
import "./ITroveDebt.sol";
import "./TroveManagerDataTypes.sol";
import "./TroveLogic.sol";
import "./WadRayMath.sol";

contract TroveManager is
    TroveManagerDataTypes,
    ITroveManager,
    ReentrancyGuardUpgradeable
{
    string public constant NAME = "TroveManager";
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using TroveLogic for DataTypes.TroveData;

    // --- Connected contract declarations ---

    address public borrowerOperationsAddress;
    address public wethAddress;

    IStabilityPool public override stabilityPool;

    ITroveManagerLiquidations internal troveManagerLiquidations;
    ITroveManagerRedemptions internal troveManagerRedemptions;

    ICollSurplusPool collSurplusPool;

    // A doubly linked list of Troves, sorted by their sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    // --- Data structures ---

    uint256 public constant SECONDS_IN_ONE_MINUTE = 60;
    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;

    uint256 public baseRate;

    // The timestamp of the latest fee operation (redemption or new USDE issuance)
    uint256 public lastFeeOperationTime;

    mapping(address => DataTypes.Trove) public Troves;

    DataTypes.TroveData internal troveData;

    mapping(address => uint256) public totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    mapping(address => uint256) public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    mapping(address => uint256) public totalCollateralSnapshot;

    /*
     * E_Coll and E_USDEDebt track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
     *
     * An collateral gain of ( stake * [E_Coll[collateral] - E_Coll[collateral](0)] )
     * A USDEDebt increase  of ( stake * [E_USDEDebt[collateral] - E_USDEDebt[collateral](0)] )
     *
     * Where E_Coll[collateral](0) and E_USDEDebt[collateral](0) are snapshots of E_Coll[collateral] and E_USDEDebt[collateral] for the active Trove taken at the instant the stake was made
     */
    mapping(address => uint256) public E_Coll;
    mapping(address => uint256) public E_USDEDebt;

    // Map addresses with active troves to their RewardSnapshot
    mapping(address => DataTypes.RewardSnapshot) rewardSnapshots;

    // Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] public TroveOwners;

    // Error trackers for the trove redistribution calculation
    mapping(address => uint256) public lastCollError_Redistribution;
    mapping(address => uint256) public lastUSDEDebtError_Redistribution;

    bool internal paused;

    modifier whenNotPaused() {
        if (paused) {
            revert Errors.ProtocolPaused();
        }
        _;
    }

    // --- Dependency setter ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _troveDebtAddress,
        address _interestRateAddress
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _requireIsContract(_troveDebtAddress);
        _requireIsContract(_interestRateAddress);
        troveDebt = ITroveDebt(_troveDebtAddress);
        // init trove debt
        troveData.borrowIndex = uint128(WadRayMath.ray());
        troveData.interestRateAddress = _interestRateAddress;
        troveData.troveManagerAddress = address(this);
        troveData.troveDebtAddress = _troveDebtAddress;
        troveData.factor = DECIMAL_PRECISION / 10;
        emit TroveDebtAddressChanged(_troveDebtAddress);
    }

    function setTroveInterestRateStrategyAddress(
        address _interestRateAddress
    ) external onlyOwner {
        _requireIsContract(_interestRateAddress);
        troveData.interestRateAddress = _interestRateAddress;
        emit TroveInterestRateStrategyAddressChanged(_interestRateAddress);
    }

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _usdeTokenAddress,
        address _sortedTrovesAddress,
        address _troveManagerLiquidationsAddress,
        address _troveManagerRedemptionsAddress,
        address _collateralManagerAddress
    ) external override onlyOwner {
        _requireIsContract(_borrowerOperationsAddress);
        _requireIsContract(_activePoolAddress);
        _requireIsContract(_defaultPoolAddress);
        _requireIsContract(_stabilityPoolAddress);
        _requireIsContract(_gasPoolAddress);
        _requireIsContract(_collSurplusPoolAddress);
        _requireIsContract(_priceFeedAddress);
        _requireIsContract(_usdeTokenAddress);
        _requireIsContract(_sortedTrovesAddress);
        _requireIsContract(_troveManagerLiquidationsAddress);
        _requireIsContract(_troveManagerRedemptionsAddress);
        _requireIsContract(_collateralManagerAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        usdeToken = IUSDEToken(_usdeTokenAddress);
        troveData.usdeTokenAddress = _usdeTokenAddress;
        sortedTroves = ISortedTroves(_sortedTrovesAddress);

        troveManagerLiquidations = ITroveManagerLiquidations(
            _troveManagerLiquidationsAddress
        );
        troveManagerRedemptions = ITroveManagerRedemptions(
            _troveManagerRedemptionsAddress
        );

        collateralManager = ICollateralManager(_collateralManagerAddress);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit USDETokenAddressChanged(_usdeTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit TroveManagerLiquidationsAddressChanged(
            _troveManagerLiquidationsAddress
        );
        emit TroveManagerRedemptionsAddressChanged(
            _troveManagerRedemptionsAddress
        );
        emit CollateralManagerAddressChanged(_collateralManagerAddress);
    }

    // --- Getters ---

    function getTroveNormalizedDebt() external view override returns (uint256) {
        return troveData.getNormalizedDebt();
    }

    function getTroveOwnersCount() external view override returns (uint256) {
        return TroveOwners.length;
    }

    function getTroveFromTroveOwnersArray(
        uint256 _index
    ) external view override returns (address) {
        return TroveOwners[_index];
    }

    // --- Trove Liquidation functions ---

    // Single liquidation function. Closes the trove if its ICR is lower than the minimum collateral ratio.
    function liquidate(
        address _borrower
    ) external override whenNotPaused nonReentrant {
        _requireTroveIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        troveManagerLiquidations.batchLiquidateTroves(borrowers, msg.sender);
    }

    /*
     * Liquidate a sequence of troves. Closes a maximum number of n under-collateralized Troves,
     * starting from the one with the lowest collateral ratio in the system, and moving upwards
     */
    function liquidateTroves(
        uint256 _n
    ) external override whenNotPaused nonReentrant {
        troveManagerLiquidations.liquidateTroves(_n, msg.sender);
    }

    /*
     * Attempt to liquidate a custom list of troves provided by the caller.
     */
    function batchLiquidateTroves(
        address[] calldata _troveArray
    ) public override whenNotPaused nonReentrant {
        troveManagerLiquidations.batchLiquidateTroves(_troveArray, msg.sender);
    }

    // --- Liquidation helper functions ---

    // Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
    function movePendingTroveRewardsToActivePool(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _USDE,
        uint256[] memory _collAmounts
    ) external override {
        _requireCallerIsTML();
        _movePendingTroveRewardsToActivePool(
            _activePool,
            _defaultPool,
            _USDE,
            _collAmounts,
            getCollateralSupport()
        );
    }

    function _movePendingTroveRewardsToActivePool(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _USDE,
        uint256[] memory _collAmounts,
        address[] memory _collaterals
    ) internal {
        _defaultPool.decreaseUSDEDebt(_USDE);
        _activePool.increaseUSDEDebt(_USDE);
        _defaultPool.sendCollateralToActivePool(_collaterals, _collAmounts);
    }

    // --- Redemption functions ---

    // Redeem as much collateral as possible from _borrower's Trove in exchange for USDE up to _maxUSDEamount

    /* Send _USDEamount USDE to the system and redeem the corresponding amount of collateral from as many Troves as are needed to fill the redemption
     * request.  Applies pending rewards to a Trove before reducing its debt and coll.
     *
     * Note that if _amount is very large, this function can run out of gas, specially if traversed troves are small. This can be easily avoided by
     * splitting the total _amount in appropriate chunks and calling the function multiple times.
     *
     * Param `_maxIterations` can also be provided, so the loop through Troves is capped (if it’s zero, it will be ignored).This makes it easier to
     * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
     * of the trove list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
     * costs can vary.
     *
     * All Troves that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
     * If the last Trove does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
     * A frontend should use getRedemptionHints() to calculate what the ICR of this Trove will be after redemption, and pass a hint for its position
     * in the sortedTroves list along with the ICR value that the hint was found for.
     *
     * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
     * is very likely that the last (partially) redeemed Trove would end up with a different ICR than what the hint is for. In this case the
     * redemption will stop after the last completely redeemed Trove and the sender will keep the remaining USDE amount, which they can attempt
     * to redeem later.
     */
    function redeemCollateral(
        uint256 _USDEAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintICR,
        uint256 _maxIterations,
        uint256 _maxFeePercentage
    ) external override whenNotPaused nonReentrant {
        troveManagerRedemptions.redeemCollateral(
            _USDEAmount,
            _firstRedemptionHint,
            _upperPartialRedemptionHint,
            _lowerPartialRedemptionHint,
            _partialRedemptionHintICR,
            _maxIterations,
            _maxFeePercentage,
            msg.sender
        );
    }

    function setPause(bool val) external override onlyOwner {
        paused = val;
        if (paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }

    // --- Helper functions ---

    // Return the current collateral ratio (ICR) of a given Trove. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(
        address _borrower,
        uint256 _price
    ) public view override returns (uint256) {
        (
            uint256[] memory currentColls,
            address[] memory collaterals,
            uint256 currentUSDEDebt
        ) = _getCurrentTroveAmounts(_borrower);
        (uint256 value, ) = _getValue(collaterals, currentColls, _price);
        uint256 ICR = ERDMath._computeCR(value, currentUSDEDebt);
        return ICR;
    }

    function getCurrentTroveAmounts(
        address _borrower
    )
        external
        view
        override
        returns (uint256[] memory, address[] memory, uint256)
    {
        return _getCurrentTroveAmounts(_borrower);
    }

    function _getCurrentTroveAmounts(
        address _borrower
    ) internal view returns (uint256[] memory, address[] memory, uint256) {
        if (Troves[_borrower].status != DataTypes.Status.active) {
            return (new uint256[](0), new address[](0), 0);
        }
        (
            uint256[] memory pendingCollRewards,
            ,
            address[] memory rewardAssets
        ) = getPendingCollReward(_borrower);

        (uint256[] memory currColls, , ) = getTroveColls(_borrower);
        uint256 pendingUSDEDebtReward = getPendingUSDEDebtReward(_borrower);
        uint256[] memory newColls = ERDMath._addArray(
            currColls,
            pendingCollRewards
        );
        uint256 oldDebt = troveDebt.balanceOf(_borrower).add(
            getUSDEGasCompensation()
        );
        uint256 currentUSDEDebt = oldDebt.add(pendingUSDEDebtReward);

        return (newColls, rewardAssets, currentUSDEDebt);
    }

    function applyPendingRewards(address _borrower) external override {
        _requireCallerIsBOorTMR();
        return _applyPendingRewards(activePool, defaultPool, _borrower);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
    function _applyPendingRewards(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower
    ) internal {
        (bool has, address[] memory collaterals) = _hasPendingRewards(
            _borrower
        );
        if (has) {
            _requireTroveIsActive(_borrower);

            // Compute pending rewards
            (uint256[] memory pendingCollRewards, ) = _getPendingCollReward(
                _borrower,
                collaterals
            );
            uint256 pendingUSDEDebtReward = getPendingUSDEDebtReward(_borrower);

            // Apply pending rewards to trove's state
            troveData.updateState();
            if (pendingUSDEDebtReward > 0) {
                troveDebt.addDebt(
                    _borrower,
                    pendingUSDEDebtReward,
                    troveData.borrowIndex
                );
            }
            uint256[] memory newShares = collateralManager.applyRewards(
                _borrower,
                pendingCollRewards
            );

            troveData.updateInterestRates();

            _updateTroveRewardSnapshots(_borrower);

            // Transfer from DefaultPool to ActivePool
            _movePendingTroveRewardsToActivePool(
                _activePool,
                _defaultPool,
                pendingUSDEDebtReward,
                pendingCollRewards,
                collaterals
            );

            emit TroveUpdated(
                _borrower,
                troveDebt.balanceOf(_borrower).add(getUSDEGasCompensation()),
                collaterals,
                newShares,
                DataTypes.TroveManagerOperation.applyPendingRewards
            );
        }
    }

    // Update borrower's snapshots of E_Coll and E_USDEDebt to reflect the current values
    function updateTroveRewardSnapshots(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _updateTroveRewardSnapshots(_borrower);
    }

    function _updateTroveRewardSnapshots(address _borrower) internal {
        address[] memory collaterals = getCollateralSupport();
        uint256 collLen = collaterals.length;
        uint256 i = 0;
        for (; i < collLen; ) {
            address collateral = collaterals[i];
            rewardSnapshots[_borrower].collShares[collateral] = E_Coll[
                collateral
            ];
            rewardSnapshots[_borrower].USDEDebt[collateral] = E_USDEDebt[
                collateral
            ];
            unchecked {
                ++i;
            }
        }
        emit TroveSnapshotsUpdated(block.timestamp);
    }

    // Get the borrower's pending accumulated ETH/wrapperETH reward, earned by their stake
    function getPendingCollReward(
        address _borrower
    )
        public
        view
        override
        returns (uint256[] memory, uint256[] memory, address[] memory)
    {
        address[] memory collaterals = getCollateralSupport();
        if (Troves[_borrower].status != DataTypes.Status.active) {
            return (new uint256[](0), new uint256[](0), collaterals);
        }

        (
            uint256[] memory pendingCollRewards,
            uint256[] memory adjustedRewards
        ) = _getPendingCollReward(_borrower, collaterals);
        return (pendingCollRewards, adjustedRewards, collaterals);
    }

    function _getPendingCollReward(
        address _borrower,
        address[] memory _collaterals
    ) internal view returns (uint256[] memory, uint256[] memory) {
        uint256 collLen = _collaterals.length;
        uint256[] memory pendingCollRewards = new uint256[](collLen);
        uint256[] memory pendingShareRewards = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            address collateral = _collaterals[i];
            uint256 snapshotCollReward = rewardSnapshots[_borrower].collShares[
                collateral
            ];
            uint256 rewardPerUnitStaked = E_Coll[collateral].sub(
                snapshotCollReward
            );
            if (rewardPerUnitStaked == 0) {
                pendingCollRewards[i] = 0;
                unchecked {
                    ++i;
                }
                continue;
            }
            uint256 stake = Troves[_borrower].stakes[collateral];
            uint256 collReward = stake.mul(rewardPerUnitStaked).div(
                DECIMAL_PRECISION
            );
            pendingCollRewards[i] = collateralManager.getAmount(
                _collaterals[i],
                collReward
            );
            pendingShareRewards[i] = collReward;
            unchecked {
                ++i;
            }
        }
        return (pendingCollRewards, pendingShareRewards);
    }

    // Get the borrower's pending accumulated USDE reward, earned by their stake
    function getPendingUSDEDebtReward(
        address _borrower
    ) public view override returns (uint256) {
        if (Troves[_borrower].status != DataTypes.Status.active) {
            return 0;
        }
        uint256 pendingUSDEDebtReward;
        address[] memory collaterals = getCollateralSupport();
        uint256 collLen = collaterals.length;
        uint256 i = 0;
        for (; i < collLen; ) {
            address collateral = collaterals[i];
            uint256 snapshotUSDEDebt = rewardSnapshots[_borrower].USDEDebt[
                collateral
            ];
            uint256 rewardPerUnitStaked = E_USDEDebt[collateral].sub(
                snapshotUSDEDebt
            );
            if (rewardPerUnitStaked == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }

            uint256 stake = Troves[_borrower].stakes[collateral];

            uint256 assetUSDEReward = stake.mul(rewardPerUnitStaked).div(
                DECIMAL_PRECISION
            );
            pendingUSDEDebtReward = pendingUSDEDebtReward.add(assetUSDEReward);
            unchecked {
                ++i;
            }
        }

        return pendingUSDEDebtReward;
    }

    function hasPendingRewards(
        address _borrower
    ) public view override returns (bool) {
        (bool has, ) = _hasPendingRewards(_borrower);
        return has;
    }

    function _hasPendingRewards(
        address _borrower
    ) internal view returns (bool, address[] memory) {
        /*
         * A Trove has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
         * this indicates that rewards have occured since the snapshot was made, and the user therefore has
         * pending rewards
         */
        if (Troves[_borrower].status != DataTypes.Status.active) {
            return (false, new address[](0));
        }
        address[] memory collaterals = getCollateralSupport();
        uint256 collLen = collaterals.length;
        uint256 i = 0;
        for (; i < collLen; ) {
            address collateral = collaterals[i];
            if (
                rewardSnapshots[_borrower].collShares[collateral] <
                E_Coll[collateral]
            ) {
                return (true, collaterals);
            }
            unchecked {
                ++i;
            }
        }
        return (false, collaterals);
    }

    // Return the Troves entire debt and coll, including pending rewards from redistributions.
    function getEntireDebtAndColl(
        address _borrower
    )
        public
        view
        override
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256[] memory,
            address[] memory
        )
    {
        if (uint256(Troves[_borrower].status) != 1) {
            return (0, new uint256[](0), 0, new uint256[](0), new address[](0));
        }
        uint256 debt = troveDebt.balanceOf(_borrower).add(
            getUSDEGasCompensation()
        );
        (
            uint256[] memory amounts,
            ,
            address[] memory collaterals
        ) = getTroveColls(_borrower);

        uint256 pendingUSDEDebtReward = getPendingUSDEDebtReward(_borrower);
        (uint256[] memory pendingCollRewards, , ) = getPendingCollReward(
            _borrower
        );

        debt = debt.add(pendingUSDEDebtReward);
        uint256[] memory colls = ERDMath._addArray(amounts, pendingCollRewards);
        return (
            debt,
            colls,
            pendingUSDEDebtReward,
            pendingCollRewards,
            collaterals
        );
    }

    function removeStake(address _borrower) external override {
        _requireCallerIsBOorTMLorTMR();
        return _removeStake(_borrower);
    }

    // Remove borrower's stake from the totalStakes sum, and set their stake to 0
    function _removeStake(address _borrower) internal {
        address[] memory collaterals = getCollateralSupport();
        uint256 collLen = collaterals.length;
        uint256 i = 0;
        for (; i < collLen; ) {
            address collateral = collaterals[i];
            uint256 stake = Troves[_borrower].stakes[collateral];
            if (stake != 0) {
                totalStakes[collateral] = totalStakes[collateral].sub(stake);
                Troves[_borrower].stakes[collateral] = 0;
            }
            unchecked {
                ++i;
            }
        }
    }

    function updateStakeAndTotalStakes(address _borrower) external override {
        _requireCallerIsBOorTMR();
        return _updateStakeAndTotalStakes(_borrower);
    }

    // Update borrower's stake based on their latest collateral value
    function _updateStakeAndTotalStakes(address _borrower) internal {
        address collateral;
        uint256 oldStake;
        uint256 newStake;
        (
            address[] memory collaterals,
            uint256[] memory shares
        ) = collateralManager.getCollateralShares(_borrower);
        uint256 collLen = collaterals.length;
        uint256 i = 0;
        for (; i < collLen; ) {
            collateral = collaterals[i];
            oldStake = Troves[_borrower].stakes[collateral];
            newStake = _computeNewStake(collateral, shares[i]);
            Troves[_borrower].stakes[collateral] = newStake;
            totalStakes[collateral] = totalStakes[collateral].sub(oldStake).add(
                newStake
            );
            emit TotalStakesUpdated(collateral, totalStakes[collateral]);
            unchecked {
                ++i;
            }
        }
    }

    // Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
    function _computeNewStake(
        address _collateral,
        uint256 _share
    ) internal view returns (uint256) {
        uint256 stake;
        if (totalCollateralSnapshot[_collateral] == 0) {
            stake = _share;
        } else {
            /*
             * The following assert() holds true because:
             * - The system always contains >= 1 trove
             * - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
             * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
             */
            if (totalStakesSnapshot[_collateral] == 0) {
                revert Errors.TM_ZeroValue();
            }
            stake = _share.mul(totalStakesSnapshot[_collateral]).div(
                totalCollateralSnapshot[_collateral]
            );
        }
        return stake;
    }

    function redistributeDebtAndColl(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _debt,
        address[] memory _collaterals,
        uint256[] memory _colls,
        uint256[] memory _proratedDebtForCollaterals
    ) external override {
        _requireCallerIsTML();
        if (_debt == 0) {
            return;
        }

        /*
         * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
         * error correction, to keep the cumulative error low in the running totals E_Coll and E_USDEDebt:
         *
         * 1) Form numerators which compensate for the floor division errors that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratios.
         * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
         * 4) Store these errors for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint256 collLen = _collaterals.length;
        uint256 i = 0;
        for (; i < collLen; ) {
            uint256 share = collateralManager.getShare(
                _collaterals[i],
                _colls[i]
            );
            address collateral = _collaterals[i];
            uint256 stake = totalStakes[collateral];
            uint256 collNumerator = share.mul(DECIMAL_PRECISION).add(
                lastCollError_Redistribution[collateral]
            );
            uint256 USDEDebtNumerator = _proratedDebtForCollaterals[i]
                .mul(DECIMAL_PRECISION)
                .add(lastUSDEDebtError_Redistribution[collateral]);
            if (stake != 0) {
                uint256 collRewardPerUnitStaked = collNumerator.div(stake);
                uint256 USDEDebtRewardPerUnitStaked = USDEDebtNumerator.div(
                    stake
                );

                // Get the per-unit-staked terms
                lastCollError_Redistribution[collateral] = collNumerator.sub(
                    collRewardPerUnitStaked.mul(stake)
                );
                lastUSDEDebtError_Redistribution[collateral] = USDEDebtNumerator
                    .sub(USDEDebtRewardPerUnitStaked.mul(stake));

                // Add per-unit-staked terms to the running totals
                E_Coll[collateral] = E_Coll[collateral].add(
                    collRewardPerUnitStaked
                );
                E_USDEDebt[collateral] = E_USDEDebt[collateral].add(
                    USDEDebtRewardPerUnitStaked
                );
                emit ETermsUpdated(
                    collateral,
                    E_Coll[collateral],
                    E_USDEDebt[collateral]
                );
            }
            unchecked {
                ++i;
            }
        }

        // Transfer coll and debt from ActivePool to DefaultPool
        _activePool.decreaseUSDEDebt(_debt);
        _defaultPool.increaseUSDEDebt(_debt);
        _activePool.sendCollateral(address(_defaultPool), _collaterals, _colls);
    }

    function closeTrove(address _borrower) external override {
        _requireCallerIsBOorTMLorTMR();
        return _closeTrove(_borrower, _getStatus());
    }

    function _getStatus() internal view returns (DataTypes.Status) {
        if (msg.sender == borrowerOperationsAddress) {
            return DataTypes.Status.closedByOwner;
        }
        if (msg.sender == address(troveManagerLiquidations)) {
            return DataTypes.Status.closedByLiquidation;
        }
        if (msg.sender == address(troveManagerRedemptions)) {
            return DataTypes.Status.closedByRedemption;
        }
        return DataTypes.Status.nonExistent;
    }

    function _closeTrove(
        address _borrower,
        DataTypes.Status closedStatus
    ) internal {
        if (
            closedStatus == DataTypes.Status.nonExistent ||
            closedStatus == DataTypes.Status.active
        ) {
            revert Errors.TM_BadClosedStatus();
        }

        uint256 TroveOwnersArrayLength = TroveOwners.length;
        if (TroveOwnersArrayLength <= 1 || sortedTroves.getSize() <= 1) {
            revert Errors.TM_OnlyOneTroveLeft();
        }
        uint256 oldDebt = troveDebt.balanceOf(_borrower);

        troveData.updateState();
        troveDebt.subDebt(_borrower, oldDebt, troveData.borrowIndex);

        Troves[_borrower].status = closedStatus;
        address[] memory collaterals = collateralManager.clearEToken(
            _borrower,
            closedStatus
        );

        uint256 collLend = collaterals.length;
        uint256 i = 0;
        for (; i < collLend; ) {
            address collateral = collaterals[i];
            rewardSnapshots[_borrower].collShares[collateral] = 0;
            rewardSnapshots[_borrower].USDEDebt[collateral] = 0;
            unchecked {
                ++i;
            }
        }
        troveData.updateInterestRates();
        _removeTroveOwner(_borrower, TroveOwnersArrayLength);
        sortedTroves.remove(_borrower);
    }

    /*
     * Updates snapshots of system total stakes and total collateral, excluding a given collateral remainder from the calculation.
     * Used in a liquidation sequence.
     *
     * The calculation excludes a portion of collateral that is in the ActivePool:
     *
     * the total ETH gas compensation from the liquidation sequence
     *
     * The ETH as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
     */
    function updateSystemSnapshots_excludeCollRemainder(
        IActivePool _activePool,
        address[] memory _collaterals,
        uint256[] memory _collRemainder
    ) external override {
        _requireCallerIsTML();
        uint256 collLend = _collaterals.length;
        uint256[] memory stakesSnapshot = new uint256[](collLend);
        uint256[] memory collateralsSnapshot = new uint256[](collLend);
        uint256 i = 0;
        for (; i < collLend; ) {
            uint256 remaind = _collRemainder[i];
            address collateral = _collaterals[i];
            if (remaind != 0) {
                totalStakesSnapshot[collateral] = totalStakes[collateral];
                uint256 activeColl = _activePool.getCollateralAmount(
                    collateral
                );
                uint256 liquidatedColl = defaultPool.getCollateralAmount(
                    collateral
                );
                uint256 totalColl = activeColl.sub(remaind).add(liquidatedColl);
                uint256 totalShare = collateralManager.getShare(
                    collateral,
                    totalColl
                );
                totalCollateralSnapshot[collateral] = totalShare;
            }
            stakesSnapshot[i] = totalStakesSnapshot[collateral];
            collateralsSnapshot[i] = totalCollateralSnapshot[collateral];
            unchecked {
                ++i;
            }
        }
        emit SystemSnapshotsUpdated(stakesSnapshot, collateralsSnapshot);
    }

    // Push the owner's address to the Trove owners list, and record the corresponding array index on the Trove struct
    function addTroveOwnerToArray(
        address _borrower
    ) external override returns (uint256 index) {
        _requireCallerIsBorrowerOperations();
        return _addTroveOwnerToArray(_borrower);
    }

    function _addTroveOwnerToArray(
        address _borrower
    ) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 troves. No risk of overflow, since troves have minimum USDE
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 USDE dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

        // Push the Troveowner to the array
        TroveOwners.push(_borrower);

        // Record the index of the new Troveowner on their Trove struct
        index = uint128(TroveOwners.length.sub(1));
        Troves[_borrower].arrayIndex = index;

        return index;
    }

    /*
     * Remove a Trove owner from the TroveOwners array, not preserving array order. Removing owner 'B' does the following:
     * [A B C D E] => [A E C D], and updates E's Trove struct to point to its new array index.
     */
    function _removeTroveOwner(
        address _borrower,
        uint256 TroveOwnersArrayLength
    ) internal {
        DataTypes.Status troveStatus = Troves[_borrower].status;
        // It’s set in caller function `_closeTrove`
        if (
            troveStatus == DataTypes.Status.nonExistent ||
            troveStatus == DataTypes.Status.active
        ) {
            revert Errors.TM_BadClosedStatus();
        }

        uint128 index = Troves[_borrower].arrayIndex;
        uint256 length = TroveOwnersArrayLength;
        uint256 idxLast = length.sub(1);

        if (index > idxLast) {
            revert Errors.TM_BadValue();
        }

        address addressToMove = TroveOwners[idxLast];

        TroveOwners[index] = addressToMove;
        Troves[addressToMove].arrayIndex = index;
        emit TroveIndexUpdated(addressToMove, index);

        TroveOwners.pop();
    }

    function setFactor(uint256 _factor) external override {
        if (msg.sender != address(collateralManager)) {
            revert Errors.Caller_NotCM();
        }
        troveData.factor = _factor;
    }

    function getFactor() external view override returns (uint256) {
        return troveData.factor;
    }

    // --- Recovery Mode and TCR functions ---

    function getTCR(uint256 _price) external view override returns (uint256) {
        // (, , uint256 value) = getEntireSystemColl(_price);
        // return _getTCR(value);
        (
            address[] memory collaterals,
            uint256[] memory colls
        ) = getEntireSystemColl();
        (uint256 value, ) = _getValue(collaterals, colls, _price);
        return _getTCR(value);
    }

    function checkRecoveryMode(
        uint256 _price
    ) external view override returns (bool) {
        uint256 debt = getEntireSystemDebt();
        (, , uint256 value) = getEntireSystemColl(_price);
        return _checkRecoveryMode(value, debt, getCCR());
    }

    // --- Redemption fee functions ---

    function updateBaseRate(uint256 newBaseRate) external override {
        _requireCallerIsTMR();
        //assert(newBaseRate <= DECIMAL_PRECISION); // This is already enforced in the line above
        if (newBaseRate == 0) {
            revert Errors.TM_BadBaseRate();
        }
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);
        uint256 timePassed = block.timestamp.sub(lastFeeOperationTime);
        _updateLastFeeOpTime(timePassed);
    }

    function getRedemptionRate() public view override returns (uint256) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay()
        public
        view
        override
        returns (uint256)
    {
        (uint256 decayedBaseRate, ) = calcDecayedBaseRate();
        return _calcRedemptionRate(decayedBaseRate);
    }

    function _calcRedemptionRate(
        uint256 _baseRate
    ) internal view returns (uint256) {
        return
            ERDMath._min(
                collateralManager.getRedemptionFeeFloor().add(_baseRate),
                DECIMAL_PRECISION // cap at a maximum of 100%
            );
    }

    function getRedemptionFeeWithDecay(
        uint256 _collDrawn,
        uint256[] memory _collDrawns
    ) external view override returns (uint256, uint256[] memory) {
        return
            _calcRedemptionFee(
                getRedemptionRateWithDecay(),
                _collDrawn,
                _collDrawns
            );
    }

    function _calcRedemptionFee(
        uint256 _redemptionRate,
        uint256 _collDrawn,
        uint256[] memory _collDrawns
    ) internal pure returns (uint256, uint256[] memory) {
        uint256 redemptionFee = _redemptionRate.mul(_collDrawn).div(
            DECIMAL_PRECISION
        );
        if (redemptionFee >= _collDrawn) {
            revert Errors.TM_BadFee();
        }
        uint256 collsLen = _collDrawns.length;
        uint256[] memory redemptionFees = new uint256[](collsLen);
        uint256 i = 0;
        for (; i < collsLen; ) {
            uint256 collDrawn = _collDrawns[i];
            if (collDrawn != 0) {
                redemptionFees[i] = _redemptionRate.mul(collDrawn).div(
                    DECIMAL_PRECISION
                );
                if (redemptionFees[i] >= collDrawn) {
                    revert Errors.TM_BadFee();
                }
            }
            unchecked {
                ++i;
            }
        }
        return (redemptionFee, redemptionFees);
    }

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint256) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay()
        public
        view
        override
        returns (uint256)
    {
        (uint256 decayedBaseRate, ) = calcDecayedBaseRate();
        return _calcBorrowingRate(decayedBaseRate);
    }

    function _calcBorrowingRate(
        uint256 _baseRate
    ) internal view returns (uint256) {
        return
            ERDMath._min(
                collateralManager.getBorrowingFeeFloor().add(_baseRate),
                collateralManager.getMaxBorrowingFee()
            );
    }

    function getBorrowingFee(
        uint256 _USDEDebt
    ) external view override returns (uint256) {
        return _calcBorrowingFee(getBorrowingRate(), _USDEDebt);
    }

    function getBorrowingFeeWithDecay(
        uint256 _USDEDebt
    ) external view override returns (uint256) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _USDEDebt);
    }

    function _calcBorrowingFee(
        uint256 _borrowingRate,
        uint256 _USDEDebt
    ) internal pure returns (uint256) {
        return _borrowingRate.mul(_USDEDebt).div(DECIMAL_PRECISION);
    }

    // Updates the baseRate state variable based on time elapsed since the last redemption or USDE borrowing operation.
    function decayBaseRateFromBorrowing() external override {
        _requireCallerIsBorrowerOperations();

        (uint256 decayedBaseRate, uint256 timePassed) = calcDecayedBaseRate();
        // assert(decayedBaseRate <= DECIMAL_PRECISION); // The baseRate can decay to 0
        if (decayedBaseRate > DECIMAL_PRECISION) {
            revert Errors.TM_BadValue();
        }

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);
        _updateLastFeeOpTime(timePassed);
    }

    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime(uint256 _timePassed) internal {
        if (_timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function calcDecayedBaseRate()
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 timePassed = block.timestamp.sub(lastFeeOperationTime);
        uint256 minutesPassed = timePassed.div(SECONDS_IN_ONE_MINUTE);
        uint256 decayFactor = ERDMath._decPow(
            MINUTE_DECAY_FACTOR,
            minutesPassed
        );
        return (baseRate.mul(decayFactor).div(DECIMAL_PRECISION), timePassed);
    }

    // --- 'require' wrapper functions ---

    function _requireIsContract(address _contract) internal view {
        if (!_contract.isContract()) {
            revert Errors.NotContract();
        }
    }

    function _requireCallerIsBorrowerOperations() internal view {
        if (msg.sender != borrowerOperationsAddress) {
            revert Errors.Caller_NotBO();
        }
    }

    function _requireCallerIsBOorTMLorTMR() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != address(troveManagerLiquidations) &&
            msg.sender != address(troveManagerRedemptions)
        ) {
            revert Errors.Caller_NotBOOrTMLOrTMR();
        }
    }

    function _requireCallerIsBOorTMR() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != address(troveManagerRedemptions)
        ) {
            revert Errors.Caller_NotBOOrTMR();
        }
    }

    function _requireCallerIsTML() internal view {
        if (msg.sender != address(troveManagerLiquidations)) {
            revert Errors.Caller_NotTML();
        }
    }

    function _requireCallerIsTMR() internal view {
        if (msg.sender != address(troveManagerRedemptions)) {
            revert Errors.Caller_NotTMR();
        }
    }

    function _requireTroveIsActive(address _borrower) internal view {
        if (Troves[_borrower].status != DataTypes.Status.active) {
            revert Errors.TM_TroveNotExistOrClosed();
        }
    }

    // --- Trove property getters ---

    function getTroveStatus(
        address _borrower
    ) external view override returns (DataTypes.Status) {
        return Troves[_borrower].status;
    }

    function getTroveDebt(
        address _borrower
    ) external view override returns (uint256) {
        if (uint256(Troves[_borrower].status) != 1) {
            return 0;
        }
        return troveDebt.balanceOf(_borrower).add(getUSDEGasCompensation());
    }

    function getTroveColl(
        address _borrower,
        address _collateral
    ) external view override returns (uint256, uint256) {
        return collateralManager.getTroveColl(_borrower, _collateral);
    }

    function getTroveColls(
        address _borrower
    )
        public
        view
        override
        returns (uint256[] memory, uint256[] memory, address[] memory)
    {
        return collateralManager.getTroveColls(_borrower);
    }

    function getTroveStake(
        address _borrower,
        address _collateral
    ) external view override returns (uint256) {
        return (Troves[_borrower].stakes[_collateral]);
    }

    function getTroveStakes(
        address _borrower
    )
        public
        view
        override
        returns (uint256[] memory, uint256, address[] memory)
    {
        address[] memory collaterals = getCollateralSupport();
        uint256 collLen = collaterals.length;
        uint256[] memory collStakes = new uint256[](collLen);
        DataTypes.Trove storage trove = Troves[_borrower];
        uint256 totalCollStake;
        uint256 i = 0;
        for (; i < collLen; ) {
            collStakes[i] = trove.stakes[collaterals[i]];
            totalCollStake = totalCollStake.add(collStakes[i]);
            unchecked {
                ++i;
            }
        }
        return (collStakes, totalCollStake, collaterals);
    }

    function getRewardSnapshotColl(
        address _borrower,
        address _collateral
    ) external view override returns (uint256) {
        return rewardSnapshots[_borrower].collShares[_collateral];
    }

    function getRewardSnapshotUSDE(
        address _borrower,
        address _collateral
    ) external view override returns (uint256) {
        return rewardSnapshots[_borrower].USDEDebt[_collateral];
    }

    // --- Trove property setters, called by BorrowerOperations ---

    function setTroveStatus(address _borrower, uint256 _num) external override {
        _requireCallerIsBorrowerOperations();
        Troves[_borrower].status = DataTypes.Status(_num);
    }

    function increaseTroveDebt(
        address _borrower,
        uint256 _debtIncrease
    ) external override returns (uint256) {
        _requireCallerIsBorrowerOperations();
        troveData.updateState();
        if (_debtIncrease > 0) {
            troveDebt.addDebt(_borrower, _debtIncrease, troveData.borrowIndex);
        }
        troveData.updateInterestRates();
        return troveDebt.balanceOf(_borrower);
    }

    function decreaseTroveDebt(
        address _borrower,
        uint256 _debtDecrease
    ) external override returns (uint256) {
        _requireCallerIsBOorTMR();
        troveData.updateState();
        if (_debtDecrease > 0) {
            troveDebt.subDebt(_borrower, _debtDecrease, troveData.borrowIndex);
        }
        troveData.updateInterestRates();
        return troveDebt.balanceOf(_borrower);
    }

    function _getValue(
        address[] memory _collaterals,
        uint256[] memory _amounts,
        uint256 _price
    ) internal view returns (uint256 totalValue, uint256[] memory values) {
        return collateralManager.getValue(_collaterals, _amounts, _price);
    }

    function getTotalValue() public view override returns (uint256) {
        // (, , uint256 totalValue) = getEntireSystemColl();
        // return totalValue;
        (
            address[] memory collaterals,
            uint256[] memory amounts
        ) = getEntireSystemColl();
        return collateralManager.getTotalValue(collaterals, amounts);
    }

    function getTroveData()
        external
        view
        override
        returns (DataTypes.TroveData memory)
    {
        return troveData;
    }

    function getCollateralSupport()
        public
        view
        override
        returns (address[] memory)
    {
        return collateralManager.getCollateralSupport();
    }

    function getCCR() public view override returns (uint256) {
        return collateralManager.getCCR();
    }

    function getUSDEGasCompensation() public view override returns (uint256) {
        return collateralManager.getUSDEGasCompensation();
    }
}
