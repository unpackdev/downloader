// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./AddressUpgradeable.sol";
import "./ITroveManagerRedemptions.sol";
import "./TroveManagerDataTypes.sol";
import "./DataTypes.sol";
import "./Errors.sol";

contract TroveManagerRedemptions is
    TroveManagerDataTypes,
    ITroveManagerRedemptions
{
    string public constant NAME = "TroveManagerRedemptions";
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // --- Connected contract declarations ---

    address public borrowerOperationsAddress;

    IStabilityPool public override stabilityPool;

    ITroveManager internal troveManager;

    ICollSurplusPool collSurplusPool;

    // A doubly linked list of Troves, sorted by their sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    // --- Data structures ---

    /*
     * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
     * Corresponds to (1 / ALPHA) in the white paper.
     */
    uint256 public constant BETA = 2;

    uint256 internal deploymentStartTime;

    // --- Dependency setter ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
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
        address _troveManagerAddress,
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
        _requireIsContract(_troveManagerAddress);
        _requireIsContract(_collateralManagerAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        usdeToken = IUSDEToken(_usdeTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        troveManager = ITroveManager(_troveManagerAddress);
        collateralManager = ICollateralManager(_collateralManagerAddress);

        deploymentStartTime = block.timestamp;

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit USDETokenAddressChanged(_usdeTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit CollateralManagerAddressChanged(_collateralManagerAddress);
    }

    function init(address _troveDebtAddress) external onlyOwner {
        _requireIsContract(_troveDebtAddress);

        troveDebt = ITroveDebt(_troveDebtAddress);

        emit TroveDebtAddressChanged(_troveDebtAddress);
    }

    // --- Getters ---

    function getCollateralSupport()
        public
        view
        override
        returns (address[] memory)
    {
        return troveManager.getCollateralSupport();
    }

    // --- Redemption functions ---

    // Redeem as much collateral as possible from _borrower's Trove in exchange for USDE up to _maxUSDEamount
    function _redeemCollateralFromTrove(
        DataTypes.ContractsCache memory _contractsCache,
        address _borrower,
        uint256 _maxUSDEamount,
        uint256 _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintICR
    )
        internal
        returns (DataTypes.SingleRedemptionValues memory singleRedemption)
    {
        DataTypes.ContractsCache memory contractsCache = _contractsCache;
        uint256 price = _price;
        address borrower = _borrower;
        address upperPartialRedemptionHint = _upperPartialRedemptionHint;
        address lowerPartialRedemptionHint = _lowerPartialRedemptionHint;
        uint256 partialRedemptionHintICR = _partialRedemptionHintICR;
        uint256 debt;
        (uint256[] memory colls, address[] memory collAssets, ) = contractsCache
            .troveManager
            .getCurrentTroveAmounts(borrower);
        singleRedemption.collaterals = collAssets;
        {
            debt = contractsCache.troveManager.getTroveDebt(borrower);
            // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Trove minus the liquidation reserve

            singleRedemption.USDELot = ERDMath._min(
                _maxUSDEamount,
                debt.sub(USDE_GAS_COMPENSATION())
            );

            // Get the collLot of equivalent value in USD
            (
                singleRedemption.collLots,
                singleRedemption.collRemaind
            ) = _calculateCollLot(
                singleRedemption.USDELot,
                collAssets,
                colls,
                price
            );
        }
        uint256[] memory collRemainds = singleRedemption.collRemaind;

        // Decrease the debt and collateral of the current Trove according to the USDE lot and corresponding collateral to send
        uint256 newDebt = debt.sub(singleRedemption.USDELot);
        (uint256 newValue, ) = contractsCache.collateralManager.getValue(
            collAssets,
            collRemainds,
            price
        );

        uint256 gas = USDE_GAS_COMPENSATION();
        if (newDebt == gas) {
            // No debt left in the Trove (except for the liquidation reserve), therefore the trove gets closed
            troveManager.removeStake(borrower);
            troveManager.closeTrove(borrower);

            _redeemCloseTrove(contractsCache, borrower, gas, collRemainds);
            emit TroveUpdated(
                borrower,
                0,
                new address[](0),
                new uint256[](0),
                DataTypes.TroveManagerOperation.redeemCollateral
            );
        } else {
            uint256 newICR = ERDMath._computeCR(newValue, newDebt);

            /*
             * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
             * certainly result in running out of gas.
             *
             * If the resultant net debt of the partial is less than the minimum, net debt we bail.
             */
            if (
                newICR >= partialRedemptionHintICR.add(1e17) ||
                newICR <= partialRedemptionHintICR.sub(1e17) ||
                _getNetDebt(newDebt, gas) <
                contractsCache.collateralManager.getMinNetDebt()
            ) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            contractsCache.sortedTroves.reInsert(
                borrower,
                newICR,
                upperPartialRedemptionHint,
                lowerPartialRedemptionHint
            );
            uint256 USDELot = singleRedemption.USDELot;
            contractsCache.troveManager.decreaseTroveDebt(borrower, USDELot);
            uint256[] memory shares = contractsCache
                .collateralManager
                .resetEToken(borrower, collAssets, collRemainds);
            contractsCache.troveManager.updateStakeAndTotalStakes(borrower);

            emit TroveUpdated(
                borrower,
                newDebt,
                collAssets,
                shares,
                DataTypes.TroveManagerOperation.redeemCollateral
            );
        }

        return singleRedemption;
    }

    function _calculateCollLot(
        uint256 _USDELot,
        address[] memory _collaterals,
        uint256[] memory _colls,
        uint256 _price
    ) internal view returns (uint256[] memory, uint256[] memory) {
        uint256 USDELot = _USDELot;
        uint256 collLen = _colls.length;
        uint256[] memory colls = new uint256[](collLen);
        uint256[] memory remaindColls = new uint256[](collLen);
        (uint256 totalValue, uint256[] memory values) = collateralManager
            .getValue(_collaterals, _colls, _price);
        bool flag = totalValue < USDELot;
        if (flag) {
            for (uint256 i = collLen - 1; i >= 0; i--) {
                colls[i] = _colls[i];
                remaindColls[i] = 0;
                if (i == 0) {
                    break;
                }
            }
        } else {
            for (uint256 i = collLen - 1; i >= 0; i--) {
                uint256 value = values[i];
                uint256 coll = _colls[i];
                if (value != 0) {
                    if (USDELot == 0) {
                        remaindColls[i] = coll;
                        if (i == 0) {
                            break;
                        }
                        continue;
                    }
                    if (value < USDELot) {
                        colls[i] = coll;
                        USDELot = USDELot.sub(value);
                        // trove.colls[collateral] = 0;
                        remaindColls[i] = 0;
                    } else {
                        uint256 portion = USDELot.mul(_100pct).div(value);
                        uint256 offset = coll.mul(portion).div(_100pct);
                        colls[i] = offset;
                        remaindColls[i] = coll.sub(offset);
                        USDELot = 0;
                    }
                }
                if (i == 0) {
                    break;
                }
            }
        }
        return (colls, remaindColls);
    }

    /*
     * Called when a full redemption occurs, and closes the trove.
     * The redeemer swaps (debt - liquidation reserve) USDE for (debt - liquidation reserve) worth of ETH, so the USDE liquidation reserve left corresponds to the remaining debt.
     * In order to close the trove, the USDE liquidation reserve is burned, and the corresponding debt is removed from the active pool.
     * The debt recorded on the trove's struct is zero'd elswhere, in _closeTrove.
     * Any surplus collateral left in the trove, is sent to the Coll surplus pool, and can be later claimed by the borrower.
     */
    function _redeemCloseTrove(
        DataTypes.ContractsCache memory _contractsCache,
        address _borrower,
        uint256 _USDE,
        uint256[] memory _collAmounts
    ) internal {
        _contractsCache.usdeToken.burn(gasPoolAddress, _USDE);
        // Update Active Pool USDE, and send collateral to account
        _contractsCache.activePool.decreaseUSDEDebt(_USDE);
        // send collateral from Active Pool to CollSurplus Pool
        _contractsCache.collSurplusPool.accountSurplus(_borrower, _collAmounts);
        _contractsCache.activePool.sendCollateral(
            address(_contractsCache.collSurplusPool),
            getCollateralSupport(),
            _collAmounts
        );
    }

    function _isValidFirstRedemptionHint(
        ISortedTroves _sortedTroves,
        address _firstRedemptionHint,
        uint256 _price
    ) internal view returns (bool) {
        uint256 mcr = MCR();
        if (
            _firstRedemptionHint == address(0) ||
            !_sortedTroves.contains(_firstRedemptionHint) ||
            _getCurrentICR(_firstRedemptionHint, _price) < mcr
        ) {
            return false;
        }

        address nextTrove = _sortedTroves.getNext(_firstRedemptionHint);
        return
            nextTrove == address(0) || _getCurrentICR(nextTrove, _price) < mcr;
    }

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
        uint256 _USDEamount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintICR,
        uint256 _maxIterations,
        uint256 _maxFeePercentage,
        address _redeemer
    ) external override {
        _requireCallerisTroveManager();
        DataTypes.ContractsCache memory contractsCache = DataTypes
            .ContractsCache(
                troveManager,
                collateralManager,
                activePool,
                defaultPool,
                usdeToken,
                sortedTroves,
                collSurplusPool,
                gasPoolAddress
            );
        DataTypes.RedemptionTotals memory totals;
        address upperPartialRedemptionHint = _upperPartialRedemptionHint;
        address lowerPartialRedemptionHint = _lowerPartialRedemptionHint;
        uint256 partialRedemptionHintICR = _partialRedemptionHintICR;
        uint256 USDEamount = _USDEamount;

        _requireValidMaxFeePercentage(_maxFeePercentage);
        _requireAfterBootstrapPeriod();
        totals.price = priceFeed.fetchPrice();
        contractsCache.collateralManager.priceUpdate();
        _requireTCRoverMCR(totals.price);
        _requireAmountGreaterThanZero(USDEamount);
        _requireUSDEBalanceCoversRedemption(
            contractsCache.usdeToken,
            _redeemer,
            USDEamount
        );

        totals.totalUSDESupplyAtStart = getEntireSystemDebt();
        // Confirm redeemer's balance is less than total USDE supply
        if (
            contractsCache.usdeToken.balanceOf(_redeemer) >
            totals.totalUSDESupplyAtStart
        ) {
            revert Errors.TMR_BadUSDEBalance();
        }

        totals.remainingUSDE = USDEamount;
        address currentBorrower;

        if (
            _isValidFirstRedemptionHint(
                contractsCache.sortedTroves,
                _firstRedemptionHint,
                totals.price
            )
        ) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedTroves.getLast();
            uint256 mcr = MCR();
            // Find the first trove with ICR >= MCR
            while (
                currentBorrower != address(0) &&
                _getCurrentICR(currentBorrower, totals.price) < mcr
            ) {
                currentBorrower = contractsCache.sortedTroves.getPrev(
                    currentBorrower
                );
            }
        }
        // Loop through the Troves starting from the one with lowest collateral ratio until _amount of USDE is exchanged for collateral
        if (_maxIterations == 0) {
            // _maxIterations = uint256(-1);
            _maxIterations = type(uint256).max;
        }
        address[] memory collaterals = getCollateralSupport();
        while (
            currentBorrower != address(0) &&
            totals.remainingUSDE > 0 &&
            _maxIterations > 0
        ) {
            _maxIterations--;
            // Save the address of the Trove preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedTroves.getPrev(
                currentBorrower
            );

            troveManager.applyPendingRewards(currentBorrower);

            DataTypes.SingleRedemptionValues
                memory singleRedemption = _redeemCollateralFromTrove(
                    contractsCache,
                    currentBorrower,
                    totals.remainingUSDE,
                    totals.price,
                    upperPartialRedemptionHint,
                    lowerPartialRedemptionHint,
                    partialRedemptionHintICR
                );

            if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Trove

            totals.totalUSDEToRedeem = totals.totalUSDEToRedeem.add(
                singleRedemption.USDELot
            );
            totals.totalCollDrawns = ERDMath._addArray(
                totals.totalCollDrawns,
                singleRedemption.collLots
            );

            totals.remainingUSDE = totals.remainingUSDE.sub(
                singleRedemption.USDELot
            );
            currentBorrower = nextUserToCheck;
        }
        if (!ERDMath._arrayIsNonzero(totals.totalCollDrawns)) {
            revert Errors.TMR_CannotRedeem();
        }

        (uint256 totalCollDrawnValue, ) = contractsCache
            .collateralManager
            .getValue(collaterals, totals.totalCollDrawns, totals.price);

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total USDE supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(
            totalCollDrawnValue,
            totals.totalUSDESupplyAtStart
        );

        // Calculate the collateral fee
        (totals.collFee, totals.collFees) = _getRedemptionFee(
            totalCollDrawnValue,
            totals.totalCollDrawns
        );

        _requireUserAcceptsFee(
            totals.collFee,
            totalCollDrawnValue,
            _maxFeePercentage
        );

        // Send the collateral fee to the treasury/liquidityIncentive contract
        contractsCache.activePool.sendCollFees(
            getCollateralSupport(),
            totals.collFees
        );

        // totals.collToSendToRedeemer = totals.totalCollDrawn.sub(totals.collFee);

        totals.collToSendToRedeemers = ERDMath._subArray(
            totals.totalCollDrawns,
            totals.collFees
        );

        emit Redemption(
            USDEamount,
            totals.totalUSDEToRedeem,
            collaterals,
            totals.totalCollDrawns,
            totals.collFees
        );

        // Burn the total USDE that is cancelled with debt, and send the redeemed collateral to msg.sender
        contractsCache.usdeToken.burn(_redeemer, totals.totalUSDEToRedeem);
        // Update Active Pool USDE, and send collateral to account
        contractsCache.activePool.decreaseUSDEDebt(totals.totalUSDEToRedeem);
        contractsCache.activePool.sendCollateral(
            _redeemer,
            getCollateralSupport(),
            totals.collToSendToRedeemers
        );
    }

    // --- Helper functions ---

    // Return the current collateral ratio (ICR) of a given Trove. Takes a trove's pending coll and debt rewards from redistributions into account.
    function _getCurrentICR(
        address _borrower,
        uint256 _price
    ) internal view returns (uint256) {
        return troveManager.getCurrentICR(_borrower, _price);
    }

    // --- Redemption fee functions ---

    /*
     * This function has two impacts on the baseRate state variable:
     * 1) decays the baseRate based on time passed since last redemption or USDE borrowing operation.
     * then,
     * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
     */
    function _updateBaseRateFromRedemption(
        uint256 _collDrawnValue,
        uint256 _totalUSDESupply
    ) internal returns (uint256) {
        (uint256 decayedBaseRate, ) = troveManager.calcDecayedBaseRate();
        /* Convert the drawn collateral back to USDE at face value rate (1 USDE:1 USD), in order to get
         * the fraction of total supply that was redeemed at face value. */
        uint256 redeemedUSDEFraction = _collDrawnValue
            .mul(DECIMAL_PRECISION)
            .div(_totalUSDESupply);

        uint256 newBaseRate = decayedBaseRate.add(
            redeemedUSDEFraction.div(BETA)
        );
        newBaseRate = ERDMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%
        troveManager.updateBaseRate(newBaseRate);
        return newBaseRate;
    }

    function _getRedemptionFee(
        uint256 _collDrawnValue,
        uint256[] memory _collDrawns
    ) internal view returns (uint256, uint256[] memory) {
        return
            _calcRedemptionFee(
                troveManager.getRedemptionRate(),
                _collDrawnValue,
                _collDrawns
            );
    }

    function _calcRedemptionFee(
        uint256 _redemptionRate,
        uint256 _collDrawnValue,
        uint256[] memory _collDrawns
    ) internal pure returns (uint256, uint256[] memory) {
        uint256 redemptionFee = _redemptionRate.mul(_collDrawnValue).div(
            DECIMAL_PRECISION
        );
        if (redemptionFee >= _collDrawnValue) {
            revert Errors.TM_BadFee();
        }
        uint256 length = _collDrawns.length;
        uint256[] memory redemptionFees = new uint256[](length);
        uint256 i = 0;
        for (; i < length; ) {
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

    function MCR() internal view returns (uint256) {
        return collateralManager.getMCR();
    }

    function USDE_GAS_COMPENSATION() internal view returns (uint256) {
        return collateralManager.getUSDEGasCompensation();
    }

    // --- 'require' wrapper functions ---

    function _requireIsContract(address _contract) internal view {
        if (!_contract.isContract()) {
            revert Errors.NotContract();
        }
    }

    function _requireCallerisTroveManager() internal view {
        if (msg.sender != address(troveManager)) {
            revert Errors.Caller_NotTM();
        }
    }

    function _requireUSDEBalanceCoversRedemption(
        IUSDEToken _usdeToken,
        address _redeemer,
        uint256 _amount
    ) internal view {
        if (_usdeToken.balanceOf(_redeemer) < _amount) {
            revert Errors.TMR_RedemptionAmountExceedBalance();
        }
    }

    function _requireAmountGreaterThanZero(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert Errors.TMR_ZeroValue();
        }
    }

    function _requireTCRoverMCR(uint256 _price) internal view {
        if (troveManager.getTCR(_price) < MCR()) {
            revert Errors.TMR_CannotRedeemWhenTCRLessThanMCR();
        }
    }

    function _requireAfterBootstrapPeriod() internal view {
        if (
            block.timestamp <
            deploymentStartTime.add(collateralManager.getBootstrapPeriod())
        ) {
            revert Errors.TMR_RedemptionNotAllowed();
        }
    }

    function _requireValidMaxFeePercentage(
        uint256 _maxFeePercentage
    ) internal view {
        if (
            _maxFeePercentage < collateralManager.getRedemptionFeeFloor() ||
            _maxFeePercentage > DECIMAL_PRECISION
        ) {
            revert Errors.TMR_BadMaxFee();
        }
    }

    function _requireUserAcceptsFee(
        uint256 _fee,
        uint256 _amount,
        uint256 _maxFeePercentage
    ) internal pure {
        uint256 feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        if (feePercentage > _maxFeePercentage) {
            revert Errors.TMR_BadMaxFee();
        }
    }

    function updateTroves(
        address[] calldata _borrowers,
        address[] calldata _lowerHints,
        address[] calldata _upperHints
    ) external override {
        uint256 lowerHintsLen = _lowerHints.length;
        if (
            lowerHintsLen != _upperHints.length ||
            lowerHintsLen != _borrowers.length
        ) {
            revert Errors.LengthMismatch();
        }
        uint256 price = priceFeed.fetchPrice();
        collateralManager.priceUpdate();
        uint256 i = 0;
        for (; i < lowerHintsLen; ) {
            _updateTrove(_borrowers[i], _lowerHints[i], _upperHints[i], price);
            unchecked {
                ++i;
            }
        }
    }

    function _updateTrove(
        address _borrower,
        address _lowerHint,
        address _upperHint,
        uint256 _price
    ) internal {
        uint256 _ICR = troveManager.getCurrentICR(_borrower, _price);
        sortedTroves.reInsert(_borrower, _ICR, _upperHint, _lowerHint);
    }
}
