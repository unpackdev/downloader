pragma experimental ABIEncoderV2;
pragma solidity ^0.6.10;

import "./Math.sol";
import "./RhoInterfaces.sol";

/* @dev:
 * CTokens are used as collateral. "Underlying" in Rho refers to the collateral CToken's underlying token.
 * An Exp is a data type with 18 decimals, used for scaling up and precise calculations */
contract Rho is RhoInterface, Math {

	CTokenInterface public immutable cToken;
	CompInterface public immutable comp;

	uint public immutable SWAP_MIN_DURATION;
	uint public immutable SUPPLY_MIN_DURATION;
	uint public immutable MIN_SWAP_NOTIONAL = 1e18;
	uint public immutable CLOSE_GRACE_PERIOD_BLOCKS = 3000; // ~12.5 hrs
	uint public immutable CLOSE_PENALTY_PER_BLOCK_MANTISSA = 1e14;// 1% (1e16) every 25 min (100 blocks)

	constructor (
		InterestRateModelInterface interestRateModel_,
		CTokenInterface cToken_,
		CompInterface comp_,
		uint minFloatRateMantissa_,
		uint maxFloatRateMantissa_,
		uint swapMinDuration_,
		uint supplyMinDuration_,
		address admin_,
		uint liquidityLimitCTokens_
	) public {
		require(minFloatRateMantissa_ < maxFloatRateMantissa_, "Min float rate must be below max float rate");

		interestRateModel = interestRateModel_;
		cToken = cToken_;
		comp = comp_;
		minFloatRate = toExp_(minFloatRateMantissa_);
		maxFloatRate = toExp_(maxFloatRateMantissa_);
		SWAP_MIN_DURATION = swapMinDuration_;
		SUPPLY_MIN_DURATION = supplyMinDuration_;
		admin = admin_;

		supplyIndex = ONE_EXP.mantissa;
		isPaused = false;
		liquidityLimit = CTokenAmount({val:liquidityLimitCTokens_});
	}

	/* @dev Supplies liquidity to the protocol. Become the counterparty for all swap traders, in return for fees.
	 * @param cTokenSupplyAmount Amount to supply, in CTokens.
	 */
	function supply(uint cTokenSupplyAmount) public override {
		CTokenAmount memory supplyAmount = CTokenAmount({val: cTokenSupplyAmount});
		CTokenAmount memory supplierLiquidityNew = add_(supplierLiquidity, supplyAmount);
		
		require(lt_(supplierLiquidityNew, liquidityLimit), "Supply paused, above liquidity limit");
		require(isPaused == false, "Market paused");

		Exp memory cTokenExchangeRate = getExchangeRate();
		accrue(cTokenExchangeRate);
		CTokenAmount memory prevSupply = supplyAccounts[msg.sender].amount;

		CTokenAmount memory truedUpPrevSupply;
		if (prevSupply.val == 0) {
			truedUpPrevSupply = CTokenAmount({val: 0});
		} else {
			uint prevIndex = supplyAccounts[msg.sender].index;
			truedUpPrevSupply = div_(mul_(prevSupply, supplyIndex), prevIndex);
		}

		CTokenAmount memory newSupplyAmount = add_(truedUpPrevSupply, supplyAmount);

		emit Supply(msg.sender, cTokenSupplyAmount, newSupplyAmount.val);

		supplyAccounts[msg.sender].amount = newSupplyAmount;
		supplyAccounts[msg.sender].lastBlock = getBlockNumber();
		supplyAccounts[msg.sender].index = supplyIndex;

		supplierLiquidity = supplierLiquidityNew;

		transferIn(msg.sender, supplyAmount);
	}

	/* @dev Remove liquidity from protocol. Can only perform after a waiting period from supplying, to prevent interest rate manipulation
	 * @param removeCTokenAmount Amount of CTokens to remove. 0 removes all CTokens.
	 */
	function remove(uint removeCTokenAmount) public override {
		CTokenAmount memory removeAmount = CTokenAmount({val: removeCTokenAmount});
		SupplyAccount memory account = supplyAccounts[msg.sender];
		require(account.amount.val > 0, "Must withdraw from active account");
		require(getBlockNumber() - account.lastBlock >= SUPPLY_MIN_DURATION, "Liquidity must be supplied a minimum duration");

		Exp memory cTokenExchangeRate = getExchangeRate();
		CTokenAmount memory lockedCollateral = accrue(cTokenExchangeRate);
		CTokenAmount memory truedUpAccountValue = div_(mul_(account.amount, supplyIndex), account.index);

		// Remove all liquidity
		if (removeAmount.val == 0) {
			removeAmount = truedUpAccountValue;
		}
		require(lte_(removeAmount, truedUpAccountValue), "Trying to remove more than account value");
		CTokenAmount memory unlockedCollateral = sub_(supplierLiquidity, lockedCollateral);
		
		require(lte_(removeAmount, unlockedCollateral), "Removing more liquidity than is unlocked");
		require(lte_(removeAmount, supplierLiquidity), "Removing more than total supplier liquidity");

		CTokenAmount memory newAccountValue = sub_(truedUpAccountValue, removeAmount);

		emit Remove(msg.sender, removeCTokenAmount, newAccountValue.val);

		supplyAccounts[msg.sender].lastBlock = getBlockNumber();
		supplyAccounts[msg.sender].index = supplyIndex;
		supplyAccounts[msg.sender].amount = newAccountValue;

		supplierLiquidity = sub_(supplierLiquidity, removeAmount);

		transferOut(msg.sender, removeAmount);
	}

	function openPayFixedSwap(uint notionalAmount, uint maximumFixedRateMantissa) public override returns(bytes32 swapHash) {
		return openInternal(true, notionalAmount, maximumFixedRateMantissa);
	}

	function openReceiveFixedSwap(uint notionalAmount, uint minFixedRateMantissa) public override returns(bytes32 swapHash) {
		return openInternal(false, notionalAmount, minFixedRateMantissa);
	}

	/* @dev Opens a new interest rate swap
	 * @param userPayingFixed : The user can choose if they want to receive fixed or pay fixed (the protocol will take the opposite side)
	 * @param notionalAmount : The principal that interest rate payments will be based on
	 * @param fixedRateLimitMantissa : The maximum (if payingFixed) or minimum (if receivingFixed) rate the swap should succeed at. Prevents frontrunning attacks.
	 	* The amount of interest to pay over 2,102,400 blocks (~1 year), with 18 decimals of precision. Eg: 5% per block-year => 0.5e18.
	*/
	function openInternal(bool userPayingFixed, uint notionalAmount, uint fixedRateLimitMantissa) internal returns (bytes32 swapHash) {
		require(isPaused == false, "Market paused");
		require(notionalAmount >= MIN_SWAP_NOTIONAL, "Swap notional amount must exceed minimum");
		Exp memory cTokenExchangeRate = getExchangeRate();

		CTokenAmount memory lockedCollateral = accrue(cTokenExchangeRate);

		CTokenAmount memory supplierLiquidityTemp = supplierLiquidity; // copy to memory for gas
		require(lt_(supplierLiquidityTemp, liquidityLimit), "Open paused, above liquidity limit");
		
		(Exp memory swapFixedRate, int rateFactorNew) = getSwapRate(userPayingFixed, notionalAmount, lockedCollateral, supplierLiquidityTemp, cTokenExchangeRate);
		CTokenAmount memory userCollateralCTokens;
		if (userPayingFixed) {
			require(swapFixedRate.mantissa <= fixedRateLimitMantissa, "The fixed rate Rho would receive is above user's limit");
			CTokenAmount memory lockedCollateralHypothetical = add_(lockedCollateral, getReceiveFixedInitCollateral(swapFixedRate, notionalAmount, cTokenExchangeRate));
			require(lte_(lockedCollateralHypothetical, supplierLiquidityTemp), "Insufficient protocol collateral");
			userCollateralCTokens = openPayFixedSwapInternal(notionalAmount, swapFixedRate, cTokenExchangeRate);
		} else {
			require(swapFixedRate.mantissa >= fixedRateLimitMantissa, "The fixed rate Rho would pay is below user's limit");
			CTokenAmount memory lockedCollateralHypothetical = add_(lockedCollateral, getPayFixedInitCollateral(swapFixedRate, notionalAmount, cTokenExchangeRate));
			require(lte_(lockedCollateralHypothetical, supplierLiquidityTemp), "Insufficient protocol collateral");
			userCollateralCTokens = openReceiveFixedSwapInternal(notionalAmount, swapFixedRate, cTokenExchangeRate);
		}

		swapHash = keccak256(abi.encode(
			userPayingFixed,
			benchmarkIndexStored.mantissa,
			getBlockNumber(),
			swapFixedRate.mantissa,
			notionalAmount,
			userCollateralCTokens.val,
			msg.sender
		));

		require(swaps[swapHash] == false, "Duplicate swap");

		emit OpenSwap(
			swapHash,
			userPayingFixed,
			benchmarkIndexStored.mantissa,
			getBlockNumber(),
			swapFixedRate.mantissa,
			notionalAmount,
			userCollateralCTokens.val,
			msg.sender
		);

		swaps[swapHash] = true;
		rateFactor = rateFactorNew;
		transferIn(msg.sender, userCollateralCTokens);
	}


	// @dev User is paying fixed, protocol is receiving fixed
	function openPayFixedSwapInternal(uint notionalAmount, Exp memory swapFixedRate, Exp memory cTokenExchangeRate) internal returns (CTokenAmount memory userCollateralCTokens) {
		uint notionalReceivingFixedNew = add_(notionalReceivingFixed, notionalAmount);
		uint notionalPayingFloatNew = add_(notionalPayingFloat, notionalAmount);

		int parBlocksReceivingFixedNew = add_(parBlocksReceivingFixed, mul_(SWAP_MIN_DURATION, notionalAmount));

		/* avgFixedRateReceivingNew = (avgFixedRateReceiving * notionalReceivingFixed + notionalAmount * swapFixedRate) / (notionalReceivingFixed + notionalAmount);*/
		Exp memory priorFixedReceivingRate = mul_(avgFixedRateReceiving, notionalReceivingFixed);
		Exp memory orderFixedReceivingRate = mul_(swapFixedRate, notionalAmount);
		Exp memory avgFixedRateReceivingNew = div_(add_(priorFixedReceivingRate, orderFixedReceivingRate), notionalReceivingFixedNew);

		userCollateralCTokens = getPayFixedInitCollateral(swapFixedRate, notionalAmount, cTokenExchangeRate);

		notionalPayingFloat = notionalPayingFloatNew;
		notionalReceivingFixed = notionalReceivingFixedNew;
		avgFixedRateReceiving = avgFixedRateReceivingNew;
		parBlocksReceivingFixed = parBlocksReceivingFixedNew;

		return userCollateralCTokens;
	}

	// @dev User is receiving fixed, protocol is paying fixed
	function openReceiveFixedSwapInternal(uint notionalAmount, Exp memory swapFixedRate, Exp memory cTokenExchangeRate) internal returns (CTokenAmount memory userCollateralCTokens) {
		uint notionalPayingFixedNew = add_(notionalPayingFixed, notionalAmount);
		uint notionalReceivingFloatNew = add_(notionalReceivingFloat, notionalAmount);

		int parBlocksPayingFixedNew = add_(parBlocksPayingFixed, mul_(SWAP_MIN_DURATION, notionalAmount));

		/* avgFixedRatePayingNew = (avgFixedRatePaying * notionalPayingFixed + notionalAmount * swapFixedRate) / (notionalPayingFixed + notionalAmount) */
		Exp memory priorFixedPayingRate = mul_(avgFixedRatePaying, notionalPayingFixed);
		Exp memory orderFixedPayingRate = mul_(swapFixedRate, notionalAmount);
		Exp memory avgFixedRatePayingNew = div_(add_(priorFixedPayingRate, orderFixedPayingRate), notionalPayingFixedNew);

		userCollateralCTokens = getReceiveFixedInitCollateral(swapFixedRate, notionalAmount, cTokenExchangeRate);

		notionalReceivingFloat = notionalReceivingFloatNew;
		notionalPayingFixed = notionalPayingFixedNew;
		avgFixedRatePaying = avgFixedRatePayingNew;
		parBlocksPayingFixed = parBlocksPayingFixedNew;

		return userCollateralCTokens;
	}

	/* @dev Closes an existing swap, after the min swap duration. Float payment continues even if closed late.
	 * Takes params from Open event.
	 * Take caution not to unecessarily revert due to underflow / overflow, as uncloseable swaps are very dangerous.
	 */
	function close(
		bool userPayingFixed,
		uint benchmarkIndexInit,
		uint initBlock,
		uint swapFixedRateMantissa,
		uint notionalAmount,
		uint userCollateralCTokens,
		address owner
	) public override {
		Exp memory cTokenExchangeRate = getExchangeRate();
		accrue(cTokenExchangeRate);
		bytes32 swapHash = keccak256(abi.encode(
			userPayingFixed,
			benchmarkIndexInit,
			initBlock,
			swapFixedRateMantissa,
			notionalAmount,
			userCollateralCTokens,
			owner
		));
		require(swaps[swapHash] == true, "No active swap found");
		uint swapDuration = sub_(getBlockNumber(), initBlock);
		require(swapDuration >= SWAP_MIN_DURATION, "Premature close swap");
		Exp memory benchmarkIndexRatio = div_(benchmarkIndexStored, toExp_(benchmarkIndexInit));

		CTokenAmount memory userCollateral = CTokenAmount({val: userCollateralCTokens});
		Exp memory swapFixedRate = toExp_(swapFixedRateMantissa);

		CTokenAmount memory userPayout;
		if (userPayingFixed) {
			userPayout = closePayFixedSwapInternal(
				swapDuration,
				benchmarkIndexRatio,
				swapFixedRate,
				notionalAmount,
				userCollateral,
				cTokenExchangeRate
			);
		} else {
			userPayout = closeReceiveFixedSwapInternal(
				swapDuration,
				benchmarkIndexRatio,
				swapFixedRate,
				notionalAmount,
				userCollateral,
				cTokenExchangeRate
			);
		}
		uint bal = cToken.balanceOf(address(this));

		// Payout is capped by total balance
		if (userPayout.val > bal) userPayout = CTokenAmount({val: bal});

		uint lateBlocks = sub_(swapDuration, SWAP_MIN_DURATION);
		CTokenAmount memory penalty = CTokenAmount(0);

		if (lateBlocks > CLOSE_GRACE_PERIOD_BLOCKS) {
			uint penaltyBlocks = lateBlocks - CLOSE_GRACE_PERIOD_BLOCKS;
			Exp memory penaltyPercent = mul_(toExp_(CLOSE_PENALTY_PER_BLOCK_MANTISSA), penaltyBlocks);
			penaltyPercent = ONE_EXP.mantissa > penaltyPercent.mantissa ? penaltyPercent : ONE_EXP; // maximum of 100% penalty
			penalty = CTokenAmount(mul_(userPayout.val, penaltyPercent));
			userPayout = sub_(userPayout, penalty);
		}

		emit CloseSwap(swapHash, owner, userPayout.val, penalty.val, benchmarkIndexStored.mantissa);

		swaps[swapHash] = false;
		transferOut(owner, userPayout);
		transferOut(msg.sender, penalty);
	}

	// @dev User paid fixed, protocol paid fixed
	function closePayFixedSwapInternal(
		uint swapDuration,
		Exp memory benchmarkIndexRatio,
		Exp memory swapFixedRate,
		uint notionalAmount,
		CTokenAmount memory userCollateral,
		Exp memory cTokenExchangeRate
	) internal returns (CTokenAmount memory userPayout) {
		uint notionalReceivingFixedNew = subToZero_(notionalReceivingFixed, notionalAmount);
		uint notionalPayingFloatNew = subToZero_(notionalPayingFloat, mul_(notionalAmount, benchmarkIndexRatio));

		/* avgFixedRateReceiving = avgFixedRateReceiving * notionalReceivingFixed - swapFixedRate * notionalAmount / notionalReceivingFixedNew */
		Exp memory avgFixedRateReceivingNew;
		if (notionalReceivingFixedNew == 0){
			avgFixedRateReceivingNew = toExp_(0);
		} else {
			Exp memory numerator = subToZero_(mul_(avgFixedRateReceiving, notionalReceivingFixed), mul_(swapFixedRate, notionalAmount));
			avgFixedRateReceivingNew = div_(numerator, notionalReceivingFixedNew);
		}

		/* The protocol reserved enough collateral for this swap for SWAP_MIN_DURATION, but its has been longer.
		 * We have decreased lockedCollateral in `accrue` for the late blocks, meaning we decreased it by more than the "open" tx added to it in the first place.
		 */
		int parBlocksReceivingFixedNew = add_(parBlocksReceivingFixed, mul_(notionalAmount, sub_(swapDuration, SWAP_MIN_DURATION)));

		CTokenAmount memory fixedLeg = toCTokens(mul_(mul_(notionalAmount, swapDuration), swapFixedRate), cTokenExchangeRate);
		CTokenAmount memory floatLeg = toCTokens(mul_(notionalAmount, sub_(benchmarkIndexRatio, ONE_EXP)), cTokenExchangeRate);
		userPayout = subToZero_(add_(userCollateral, floatLeg), fixedLeg); // no underflows

		notionalReceivingFixed = notionalReceivingFixedNew;
		notionalPayingFloat = notionalPayingFloatNew;
		parBlocksReceivingFixed = parBlocksReceivingFixedNew;
		avgFixedRateReceiving = avgFixedRateReceivingNew;

		return userPayout;
	}

	// @dev User received fixed, protocol paid fixed
	function closeReceiveFixedSwapInternal(
		uint swapDuration,
		Exp memory benchmarkIndexRatio,
		Exp memory swapFixedRate,
		uint notionalAmount,
		CTokenAmount memory userCollateral,
		Exp memory cTokenExchangeRate
	) internal returns (CTokenAmount memory userPayout) {
		uint notionalPayingFixedNew = subToZero_(notionalPayingFixed, notionalAmount);
		uint notionalReceivingFloatNew = subToZero_(notionalReceivingFloat, mul_(notionalAmount, benchmarkIndexRatio));

		/* avgFixedRatePaying = avgFixedRatePaying * notionalPayingFixed - swapFixedRate * notionalAmount / notionalReceivingFixedNew */
		Exp memory avgFixedRatePayingNew;
		if (notionalPayingFixedNew == 0) {
			avgFixedRatePayingNew = toExp_(0);
		} else {
			Exp memory numerator = subToZero_(mul_(avgFixedRatePaying, notionalPayingFixed), mul_(swapFixedRate, notionalAmount));
			avgFixedRatePayingNew = div_(numerator, notionalReceivingFloatNew);
		}

		/* The protocol reserved enough collateral for this swap for SWAP_MIN_DURATION, but its has been longer.
		 * We have decreased lockedCollateral in `accrue` for the late blocks, meaning we decreased it by more than the "open" tx added to it in the first place.
		 */
		int parBlocksPayingFixedNew = add_(parBlocksPayingFixed, mul_(notionalAmount, sub_(swapDuration, SWAP_MIN_DURATION)));

		CTokenAmount memory fixedLeg = toCTokens(mul_(mul_(notionalAmount, swapDuration), swapFixedRate), cTokenExchangeRate);
		CTokenAmount memory floatLeg = toCTokens(mul_(notionalAmount, sub_(benchmarkIndexRatio, ONE_EXP)), cTokenExchangeRate);
		userPayout = subToZero_(add_(userCollateral, fixedLeg), floatLeg);

		notionalPayingFixed = notionalPayingFixedNew;
		notionalReceivingFloat = notionalReceivingFloatNew;
		parBlocksPayingFixed = parBlocksPayingFixedNew;
		avgFixedRatePaying = avgFixedRatePayingNew;

		return userPayout;
	}

	/* @dev Called internally at the beginning of external swap and liquidity provider functions.
	 * WRITES TO STORAGE
	 * Accounts for interest rate payments and adjust collateral requirements with the passage of time.
	 * @return lockedCollateralNew : The amount of collateral the protocol needs to keep locked.
	 */
	function accrue(Exp memory cTokenExchangeRate) internal returns (CTokenAmount memory) {
		require(getBlockNumber() >= lastAccrualBlock, "Block number decreasing");
		uint accruedBlocks = getBlockNumber() - lastAccrualBlock;
		(CTokenAmount memory lockedCollateralNew, int parBlocksReceivingFixedNew, int parBlocksPayingFixedNew) = getLockedCollateral(accruedBlocks, cTokenExchangeRate);

		if (accruedBlocks == 0) {
			return lockedCollateralNew;
		}

		Exp memory benchmarkIndexNew = getBenchmarkIndex();
		Exp memory benchmarkIndexRatio;
		
		// if first tx
		if (benchmarkIndexStored.mantissa == 0) {
			benchmarkIndexRatio = ONE_EXP;
		} else {
			benchmarkIndexRatio = div_(benchmarkIndexNew, benchmarkIndexStored);
		}
		Exp memory floatRate = sub_(benchmarkIndexRatio, ONE_EXP);

		CTokenAmount memory supplierLiquidityNew = getSupplierLiquidity(accruedBlocks, floatRate, cTokenExchangeRate);

		// supplyIndex *= supplierLiquidityNew / supplierLiquidity
		uint supplyIndexNew = supplyIndex;
		if (supplierLiquidityNew.val != 0) {
			supplyIndexNew = div_(mul_(supplyIndex, supplierLiquidityNew), supplierLiquidity);
		}

		uint notionalPayingFloatNew = mul_(notionalPayingFloat, benchmarkIndexRatio);
		uint notionalReceivingFloatNew = mul_(notionalReceivingFloat, benchmarkIndexRatio);

		/** Apply Effects **/

		parBlocksPayingFixed = parBlocksPayingFixedNew;
		parBlocksReceivingFixed = parBlocksReceivingFixedNew;

		supplierLiquidity = supplierLiquidityNew;
		supplyIndex = supplyIndexNew;

		notionalPayingFloat = notionalPayingFloatNew;
		notionalReceivingFloat = notionalReceivingFloatNew;

		benchmarkIndexStored = benchmarkIndexNew;
		lastAccrualBlock = getBlockNumber();

		emit Accrue(supplierLiquidityNew.val, lockedCollateralNew.val);
		return lockedCollateralNew;
	}

	function transferIn(address from, CTokenAmount memory cTokenAmount) internal {
		require(cToken.transferFrom(from, address(this), cTokenAmount.val) == true, "Transfer In Failed");
	}

	function transferOut(address to, CTokenAmount memory cTokenAmount) internal {
		if (cTokenAmount.val > 0) {
			require(cToken.transfer(to, cTokenAmount.val), "Transfer Out failed");
		}
	}

	// ** PUBLIC PURE HELPERS ** //

	function toCTokens(uint amount, Exp memory cTokenExchangeRate) public pure returns (CTokenAmount memory) {
		uint cTokenAmount = div_(amount, cTokenExchangeRate);
		return CTokenAmount({val: cTokenAmount});
	}

	function toUnderlying(CTokenAmount memory amount, Exp memory cTokenExchangeRate) public pure returns (uint) {
		return mul_(amount.val, cTokenExchangeRate);
	}

	// *** PUBLIC VIEW GETTERS *** //

	// @dev Calculate protocol locked collateral and parBlocks, which is a measure of the fixed rate credit/debt.
	// * Uses int to keep negatives, for correct late blocks calc when a single swap is outstanding
	function getLockedCollateral(uint accruedBlocks, Exp memory cTokenExchangeRate) public view returns (CTokenAmount memory lockedCollateral, int parBlocksReceivingFixedNew, int parBlocksPayingFixedNew) {
		parBlocksReceivingFixedNew = sub_(parBlocksReceivingFixed, mul_(accruedBlocks, notionalReceivingFixed));
		parBlocksPayingFixedNew = sub_(parBlocksPayingFixed, mul_(accruedBlocks, notionalPayingFixed));

		// Par blocks can be negative during the first or last ever swap, so floor them to 0
		uint minFloatToReceive = mul_(toUint_(parBlocksPayingFixedNew), minFloatRate);
		uint maxFloatToPay = mul_(toUint_(parBlocksReceivingFixedNew), maxFloatRate);

		uint fixedToReceive = mul_(toUint_(parBlocksReceivingFixedNew), avgFixedRateReceiving);
		uint fixedToPay = mul_(toUint_(parBlocksPayingFixedNew), avgFixedRatePaying);

		uint minCredit = add_(fixedToReceive, minFloatToReceive);
		uint maxDebt = add_(fixedToPay, maxFloatToPay);

		if (maxDebt > minCredit) {
			lockedCollateral = toCTokens(sub_(maxDebt, minCredit), cTokenExchangeRate);
		} else {
			lockedCollateral = CTokenAmount({val:0});
		}
	}

	/* @dev Calculate protocol P/L by adding the cashflows since last accrual.
	 * 		supplierLiquidity += fixedReceived + floatReceived - fixedPaid - floatPaid
	 */
	function getSupplierLiquidity(uint accruedBlocks, Exp memory floatRate, Exp memory cTokenExchangeRate) public view returns (CTokenAmount memory supplierLiquidityNew) {
		uint floatPaid = mul_(notionalPayingFloat, floatRate);
		uint floatReceived = mul_(notionalReceivingFloat, floatRate);
		uint fixedPaid = mul_(accruedBlocks, mul_(notionalPayingFixed, avgFixedRatePaying));
		uint fixedReceived = mul_(accruedBlocks, mul_(notionalReceivingFixed, avgFixedRateReceiving));

		CTokenAmount memory rec = toCTokens(add_(fixedReceived, floatReceived), cTokenExchangeRate);
		CTokenAmount memory paid = toCTokens(add_(fixedPaid, floatPaid), cTokenExchangeRate);
		supplierLiquidityNew = subToZero_(add_(supplierLiquidity, rec), paid);
	}

	// @dev Get the rate for incoming swaps
	function getSwapRate(
		bool userPayingFixed,
		uint orderNotional,
		CTokenAmount memory lockedCollateral,
		CTokenAmount memory supplierLiquidity_,
		Exp memory cTokenExchangeRate
	) public view returns (Exp memory, int) {
		(uint ratePerBlockMantissa, int rateFactorNew) = interestRateModel.getSwapRate(
			rateFactor,
			userPayingFixed,
			orderNotional,
			toUnderlying(lockedCollateral, cTokenExchangeRate),
			toUnderlying(supplierLiquidity_, cTokenExchangeRate)
		);
		return (toExp_(ratePerBlockMantissa), rateFactorNew);
	}

	// @dev The amount that must be locked up for the payFixed leg of a swap paying fixed. Used to calculate both the protocol and user's collateral.
	// = notionalAmount * SWAP_MIN_DURATION * (swapFixedRate - minFloatRate)
	function getPayFixedInitCollateral(Exp memory fixedRate, uint notionalAmount, Exp memory cTokenExchangeRate) public view returns (CTokenAmount memory) {
		Exp memory rateDelta = sub_(fixedRate, minFloatRate);
		uint amt = mul_(mul_(SWAP_MIN_DURATION, notionalAmount), rateDelta);
		return toCTokens(amt, cTokenExchangeRate);
	}

	// @dev The amount that must be locked up for the receiveFixed leg of a swap receiving fixed. Used to calculate both the protocol and user's collateral.
	// = notionalAmount * SWAP_MIN_DURATION * (maxFloatRate - swapFixedRate)
	function getReceiveFixedInitCollateral(Exp memory fixedRate, uint notionalAmount, Exp memory cTokenExchangeRate) public view returns (CTokenAmount memory) {
		Exp memory rateDelta = sub_(maxFloatRate, fixedRate);
		uint amt = mul_(mul_(SWAP_MIN_DURATION, notionalAmount), rateDelta);
		return toCTokens(amt, cTokenExchangeRate);
	}

	// @dev Interpolates to get the current borrow index from a compound CToken (or some other similar interface)
	function getBenchmarkIndex() public view returns (Exp memory) {
		Exp memory borrowIndex = toExp_(cToken.borrowIndex());
		require(borrowIndex.mantissa != 0, "Benchmark index is zero");
		uint accrualBlockNumber = cToken.accrualBlockNumber();
		require(getBlockNumber() >= accrualBlockNumber, "Bn decreasing");
		uint blockDelta = sub_(getBlockNumber(), accrualBlockNumber);

		if (blockDelta == 0) {
			return borrowIndex;
		} else {
			Exp memory borrowRateMantissa = toExp_(cToken.borrowRatePerBlock());
			Exp memory simpleInterestFactor = mul_(borrowRateMantissa, blockDelta);
			return mul_(borrowIndex, add_(simpleInterestFactor, ONE_EXP));
		}
	}

	function getExchangeRate() public view returns (Exp memory) {
		return toExp_(cToken.exchangeRateStored());
	}

	function getBlockNumber() public view virtual returns (uint) {
		return block.number;
	}

	/** ADMIN FUNCTIONS **/

	function _setInterestRateModel(InterestRateModelInterface newModel) external {
		require(msg.sender == admin, "Must be admin to set interest rate model");
		require(newModel != interestRateModel, "Resetting to same model");
		emit SetInterestRateModel(address(newModel), address(interestRateModel));
		interestRateModel = newModel;
	}

	function _setCollateralRequirements(uint minFloatRateMantissa_, uint maxFloatRateMantissa_) external {
		require(msg.sender == admin, "Must be admin to set collateral requirements");
		require(minFloatRateMantissa_ < maxFloatRateMantissa_, "Min float rate must be below max float rate");

		emit SetCollateralRequirements(minFloatRateMantissa_, maxFloatRateMantissa_);
		minFloatRate = toExp_(minFloatRateMantissa_);
		maxFloatRate = toExp_(maxFloatRateMantissa_);
	}

	function _setLiquidityLimit(uint limit_) external {
		require(msg.sender == admin, "Must be admin to set liqiudity limit");
		emit SetLiquidityLimit(limit_);
		liquidityLimit = CTokenAmount({val: limit_});
	}

	function _pause(bool isPaused_) external {
		require(msg.sender == admin, "Must be admin to pause");
		require(isPaused_ != isPaused, "Must change isPaused");
		emit SetPause(isPaused_);
		isPaused = isPaused_;
	}

	function _transferComp(address dest, uint amount) external {
		require(msg.sender == admin, "Must be admin to transfer comp");
		emit CompTransferred(dest, amount);
		comp.transfer(dest, amount);
	}

	function _delegateComp(address delegatee) external {
		require(msg.sender == admin, "Must be admin to delegate comp");
		emit CompDelegated(delegatee);
		comp.delegate(delegatee);
	}

	function _changeAdmin(address admin_) external {
		require(msg.sender == admin, "Must be admin to change admin");
		emit AdminChanged(admin, admin_);
		admin = admin_;
	}

}
