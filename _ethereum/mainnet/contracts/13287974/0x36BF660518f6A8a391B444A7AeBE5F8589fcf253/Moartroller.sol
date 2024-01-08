// SPDX-License-Identifier: BSD-3-Clause
// Thanks to Compound for their foundational work in DeFi and open-sourcing their code from which we build upon.

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// import "./console.sol";

import "./MToken.sol";
import "./ErrorReporter.sol";
import "./ExponentialNoError.sol";
import "./PriceOracle.sol";
import "./MoartrollerInterface.sol";
import "./Versionable.sol";
import "./MProxyInterface.sol";
import "./MoartrollerStorage.sol";
import "./UnionGovernanceToken.sol";
import "./MProtection.sol";
import "./LiquidityMathModelInterface.sol";
import "./LiquidityMathModelV1.sol";
import "./SafeEIP20.sol";
import "./EIP20Interface.sol";
import "./LiquidationModelInterface.sol";
import "./Initializable.sol";

/**
 * @title MOAR's Moartroller Contract
 * @author MOAR
 */
contract Moartroller is MoartrollerV6Storage, MoartrollerInterface, MoartrollerErrorReporter, ExponentialNoError, Versionable, Initializable {

    using SafeEIP20 for EIP20Interface;

    /// @notice Indicator that this is a Moartroller contract (for inspection)
    bool public constant isMoartroller = true;

    /// @notice Emitted when an admin supports a market
    event MarketListed(MToken mToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(MToken mToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(MToken mToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(MToken mToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when protection is changed
    event NewCProtection(MProtection oldCProtection, MProtection newCProtection);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPausedMToken(MToken mToken, string action, bool pauseState);

    /// @notice Emitted when a new MOAR speed is calculated for a market
    event MoarSpeedUpdated(MToken indexed mToken, uint newSpeed);

    /// @notice Emitted when a new MOAR speed is set for a contributor
    event ContributorMoarSpeedUpdated(address indexed contributor, uint newSpeed);

    /// @notice Emitted when MOAR is distributed to a supplier
    event DistributedSupplierMoar(MToken indexed mToken, address indexed supplier, uint moarDelta, uint moarSupplyIndex);

    /// @notice Emitted when MOAR is distributed to a borrower
    event DistributedBorrowerMoar(MToken indexed mToken, address indexed borrower, uint moarDelta, uint moarBorrowIndex);

    /// @notice Emitted when borrow cap for a mToken is changed
    event NewBorrowCap(MToken indexed mToken, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    /// @notice Emitted when MOAR is granted by admin
    event MoarGranted(address recipient, uint amount);

    event NewLiquidityMathModel(address oldLiquidityMathModel, address newLiquidityMathModel);

    event NewLiquidationModel(address oldLiquidationModel, address newLiquidationModel);

    /// @notice The initial MOAR index for a market
    uint224 public constant moarInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    // Custom initializer
    function initialize(LiquidityMathModelInterface mathModel, LiquidationModelInterface lqdModel) public initializer {
        admin = msg.sender;
        liquidityMathModel = mathModel;
        liquidationModel = lqdModel;
        rewardClaimEnabled = false;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (MToken[] memory) {
        MToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, MToken mToken) external view returns (bool) {
        return markets[address(mToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param mTokens The list of addresses of the mToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory mTokens) public override returns (uint[] memory) {
        uint len = mTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            MToken mToken = MToken(mTokens[i]);

            results[i] = uint(addToMarketInternal(mToken, msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param mToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(MToken mToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(mToken)];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return Error.NO_ERROR;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(mToken);

        emit MarketEntered(mToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param mTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address mTokenAddress) external override returns (uint) {
        MToken mToken = MToken(mTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the mToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = mToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(mTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(mToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        /* Set mToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete mToken from the account’s list of assets */
        // load into memory for faster iteration
        MToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == mToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        MToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketExited(mToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param mToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address mToken, address minter, uint mintAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[mToken], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[mToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        updateMoarSupplyIndex(mToken);
        distributeSupplierMoar(mToken, minter);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address mToken, address redeemer, uint redeemTokens) external override returns (uint) {
        uint allowed = redeemAllowedInternal(mToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateMoarSupplyIndex(mToken);
        distributeSupplierMoar(mToken, redeemer);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address mToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[mToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[mToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, MToken(mToken), redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param mToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address mToken, address redeemer, uint redeemAmount, uint redeemTokens) external override {
        // Shh - currently unused
        mToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param mToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address mToken, address borrower, uint borrowAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[mToken], "borrow is paused");

        if (!markets[mToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (!markets[mToken].accountMembership[borrower]) {
            // only mTokens may call borrowAllowed if borrower not in market
            require(msg.sender == mToken, "sender must be mToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(MToken(msg.sender), borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[mToken].accountMembership[borrower]);
        }

        if (oracle.getUnderlyingPrice(MToken(mToken)) == 0) {
            return uint(Error.PRICE_ERROR);
        }


        uint borrowCap = borrowCaps[mToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = MToken(mToken).totalBorrows();
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, MToken(mToken), 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: MToken(mToken).borrowIndex()});
        updateMoarBorrowIndex(mToken, borrowIndex);
        distributeBorrowerMoar(mToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param mToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address mToken,
        address payer,
        address borrower,
        uint repayAmount) external override returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[mToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: MToken(mToken).borrowIndex()});
        updateMoarBorrowIndex(mToken, borrowIndex);
        distributeBorrowerMoar(mToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param mTokenBorrowed Asset which was borrowed by the borrower
     * @param mTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address mTokenBorrowed,
        address mTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external override returns (uint) {
        // Shh - currently unused
        liquidator;

        if (!markets[mTokenBorrowed].isListed || !markets[mTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint borrowBalance = MToken(mTokenBorrowed).borrowBalanceStored(borrower);
        uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param mTokenCollateral Asset which was used as collateral and will be seized
     * @param mTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address mTokenCollateral,
        address mTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (!markets[mTokenCollateral].isListed || !markets[mTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (MToken(mTokenCollateral).moartroller() != MToken(mTokenBorrowed).moartroller()) {
            return uint(Error.MOARTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updateMoarSupplyIndex(mTokenCollateral);
        distributeSupplierMoar(mTokenCollateral, borrower);
        distributeSupplierMoar(mTokenCollateral, liquidator);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param mToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of mTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(address mToken, address src, address dst, uint transferTokens) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(mToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateMoarSupplyIndex(mToken);
        distributeSupplierMoar(mToken, src);
        distributeSupplierMoar(mToken, dst);

        return uint(Error.NO_ERROR);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, MToken(0), 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, MToken(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param mTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address mTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, MToken(mTokenModify), redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param mTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral mToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        MToken mTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        MToken[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            MToken asset = assets[i];
            address _account = account;

            // Read the balances and exchange rate from the mToken
            (oErr, vars.mTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(_account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = mul_(Exp({mantissa: vars.oraclePriceMantissa}), 10**uint256(18 - EIP20Interface(asset.getUnderlying()).decimals()));

            // Pre-compute a conversion factor from tokens -> dai (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * mTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.mTokenBalance, vars.sumCollateral);

            // Protection value calculation sumCollateral += protectionValueLocked
            // Mark to market value calculation sumCollateral += markToMarketValue
            uint protectionValueLocked;
            uint markToMarketValue;
            (protectionValueLocked, markToMarketValue) = liquidityMathModel.getTotalProtectionLockedValue(LiquidityMathModelInterface.LiquidityMathArgumentsSet(asset, _account, markets[address(asset)].collateralFactorMantissa, cprotection, oracle));
            if (vars.sumCollateral < mul_( protectionValueLocked, vars.collateralFactor)) {
                vars.sumCollateral = 0;
            } else {
                vars.sumCollateral = sub_(vars.sumCollateral, mul_( protectionValueLocked, vars.collateralFactor));
            }
            vars.sumCollateral = add_(vars.sumCollateral, protectionValueLocked);
            vars.sumCollateral = add_(vars.sumCollateral, markToMarketValue);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with mTokenModify
            if (asset == mTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);

                _account = account;
            }
        }
        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Returns the value of possible optimization left for asset
     * @param asset The MToken address
     * @param account The owner of asset
     * @return The value of possible optimization
     */
    function getMaxOptimizableValue(MToken asset, address account) public view returns(uint){
        return liquidityMathModel.getMaxOptimizableValue(
            LiquidityMathModelInterface.LiquidityMathArgumentsSet(
                asset, account, markets[address(asset)].collateralFactorMantissa, cprotection, oracle
            )
        );
    }

    /**
     * @notice Returns the value of hypothetical optimization (ignoring existing optimization used) for asset
     * @param asset The MToken address
     * @param account The owner of asset
     * @return The amount of hypothetical optimization
     */
    function getHypotheticalOptimizableValue(MToken asset, address account) public view returns(uint){
        return liquidityMathModel.getHypotheticalOptimizableValue(
            LiquidityMathModelInterface.LiquidityMathArgumentsSet(
                asset, account, markets[address(asset)].collateralFactorMantissa, cprotection, oracle
            )
        );
    }

    function liquidateCalculateSeizeUserTokens(address mTokenBorrowed, address mTokenCollateral, uint actualRepayAmount, address account) external override view returns (uint, uint) {
        return LiquidationModelInterface(liquidationModel).liquidateCalculateSeizeUserTokens(
            LiquidationModelInterface.LiquidateCalculateSeizeUserTokensArgumentsSet(
                oracle,
                this,
                mTokenBorrowed,
                mTokenCollateral,
                actualRepayAmount,
                account,
                liquidationIncentiveMantissa
            )
        );
    }


    /**
     * @notice Returns the amount of a specific asset that is locked under all c-ops
     * @param asset The MToken address
     * @param account The owner of asset
     * @return The amount of asset locked under c-ops
     */
    function getUserLockedAmount(MToken asset, address account) public override view returns(uint) {
        uint protectionLockedAmount;
        address currency = asset.underlying();

        uint256 numOfProtections = cprotection.getUserUnderlyingProtectionTokenIdByCurrencySize(account, currency);

        for (uint i = 0; i < numOfProtections; i++) {
            uint cProtectionId = cprotection.getUserUnderlyingProtectionTokenIdByCurrency(account, currency, i);
            if(cprotection.isProtectionAlive(cProtectionId)){
                protectionLockedAmount = protectionLockedAmount + cprotection.getUnderlyingProtectionLockedAmount(cProtectionId);
            }
        }

        return protectionLockedAmount;
    }



    /*** Admin Functions ***/

    /**
      * @notice Sets a new price oracle for the moartroller
      * @dev Admin function to set a new price oracle
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPriceOracle(PriceOracle newOracle) public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the moartroller
        PriceOracle oldOracle = oracle;

        // Set moartroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sets a new CProtection that is allowed to use as a collateral optimisation
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setProtection(address newCProtection) public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        MProtection oldCProtection = cprotection;
        cprotection = MProtection(newCProtection);

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewCProtection(oldCProtection, cprotection);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
    	require(msg.sender == admin, "only admin can set close factor");

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param mToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(MToken mToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[address(mToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }
    
        // TODO: this check is temporary switched off. we can make exception for UNN later

        // Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});
        //
        //
        // Check collateral factor <= 0.9
        // Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        // if (lessThanExp(highLimit, newCollateralFactorExp)) {
        //     return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        // }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(mToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(mToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

        function _setRewardClaimEnabled(bool status) external returns (uint) {
        // Check caller is admin
    	require(msg.sender == admin, "only admin can set close factor");
        rewardClaimEnabled = status;

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param mToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(MToken mToken) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (markets[address(mToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        mToken.isMToken(); // Sanity check to make sure its really a MToken

        // Note that isMoared is not in active use anymore
        markets[address(mToken)] = Market({isListed: true, isMoared: false, collateralFactorMantissa: 0});
        tokenAddressToMToken[address(mToken.underlying())] = mToken;

        _addMarketInternal(address(mToken));

        emit MarketListed(mToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address mToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != MToken(mToken), "market already added");
        }
        allMarkets.push(MToken(mToken));
    }

    /**
      * @notice Set the given borrow caps for the given mToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
      * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
      * @param mTokens The addresses of the markets (tokens) to change the borrow caps for
      * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
      */
    function _setMarketBorrowCaps(MToken[] calldata mTokens, uint[] calldata newBorrowCaps) external {
    	require(msg.sender == admin || msg.sender == borrowCapGuardian, "only admin or borrow cap guardian can set borrow caps"); 

        uint numMarkets = mTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(mTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(mTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external {
        require(msg.sender == admin, "only admin can set borrow cap guardian");

        // Save current value for inclusion in log
        address oldBorrowCapGuardian = borrowCapGuardian;

        // Store borrowCapGuardian with value newBorrowCapGuardian
        borrowCapGuardian = newBorrowCapGuardian;

        // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
        emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    function _setMintPaused(MToken mToken, bool state) public returns (bool) {
        require(markets[address(mToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        mintGuardianPaused[address(mToken)] = state;
        emit ActionPausedMToken(mToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(MToken mToken, bool state) public returns (bool) {
        require(markets[address(mToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        borrowGuardianPaused[address(mToken)] = state;
        emit ActionPausedMToken(mToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     */
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == moartrollerImplementation;
    }

    /*** MOAR Distribution ***/

    /**
     * @notice Set MOAR speed for a single market
     * @param mToken The market whose MOAR speed to update
     * @param moarSpeed New MOAR speed for market
     */
    function setMoarSpeedInternal(MToken mToken, uint moarSpeed) internal {
        uint currentMoarSpeed = moarSpeeds[address(mToken)];
        // note that MOAR speed could be set to 0 to halt liquidity rewards for a market
        Exp memory borrowIndex = Exp({mantissa: mToken.borrowIndex()});
        updateMoarSupplyIndex(address(mToken));
        updateMoarBorrowIndex(address(mToken), borrowIndex);
       if (moarSpeed != 0) {
            Market storage market = markets[address(mToken)];
            require(market.isListed == true, "MOAR market is not listed");

            if (moarSupplyState[address(mToken)].index == 0 && moarSupplyState[address(mToken)].block == 0) {
                moarSupplyState[address(mToken)] = MoarMarketState({
                    index: moarInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }

            if (moarBorrowState[address(mToken)].index == 0 && moarBorrowState[address(mToken)].block == 0) {
                moarBorrowState[address(mToken)] = MoarMarketState({
                    index: moarInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }
        }

        if (currentMoarSpeed != moarSpeed) {
            moarSpeeds[address(mToken)] = moarSpeed;
            emit MoarSpeedUpdated(mToken, moarSpeed);
        }
    }

    /**
     * @notice Accrue MOAR to the market by updating the supply index
     * @param mToken The market whose supply index to update
     */
    function updateMoarSupplyIndex(address mToken) internal {
        MoarMarketState storage supplyState = moarSupplyState[mToken];
        uint supplySpeed = moarSpeeds[mToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = MToken(mToken).totalSupply();
            uint moarAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(moarAccrued, supplyTokens) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: supplyState.index}), ratio);
            moarSupplyState[mToken] = MoarMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            supplyState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Accrue MOAR to the market by updating the borrow index
     * @param mToken The market whose borrow index to update
     */
    function updateMoarBorrowIndex(address mToken, Exp memory marketBorrowIndex) internal {
        MoarMarketState storage borrowState = moarBorrowState[mToken];
        uint borrowSpeed = moarSpeeds[mToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(MToken(mToken).totalBorrows(), marketBorrowIndex);
            uint moarAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(moarAccrued, borrowAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: borrowState.index}), ratio);
            moarBorrowState[mToken] = MoarMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            borrowState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Calculate MOAR accrued by a supplier and possibly transfer it to them
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute MOAR to
     */
    function distributeSupplierMoar(address mToken, address supplier) internal {
        MoarMarketState storage supplyState = moarSupplyState[mToken];
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({mantissa: moarSupplierIndex[mToken][supplier]});
        moarSupplierIndex[mToken][supplier] = supplyIndex.mantissa;

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = moarInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = MToken(mToken).balanceOf(supplier);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(moarAccrued[supplier], supplierDelta);
        moarAccrued[supplier] = supplierAccrued;
        emit DistributedSupplierMoar(MToken(mToken), supplier, supplierDelta, supplyIndex.mantissa);
    }

    /**
     * @notice Calculate MOAR accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute MOAR to
     */
    function distributeBorrowerMoar(address mToken, address borrower, Exp memory marketBorrowIndex) internal {
        MoarMarketState storage borrowState = moarBorrowState[mToken];
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({mantissa: moarBorrowerIndex[mToken][borrower]});
        moarBorrowerIndex[mToken][borrower] = borrowIndex.mantissa;
        
        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(MToken(mToken).borrowBalanceStored(borrower), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            uint borrowerAccrued = add_(moarAccrued[borrower], borrowerDelta);
            moarAccrued[borrower] = borrowerAccrued;
            emit DistributedBorrowerMoar(MToken(mToken), borrower, borrowerDelta, borrowIndex.mantissa);
        }
    }

    /**
     * @notice Calculate additional accrued MOAR for a contributor since last accrual
     * @param contributor The address to calculate contributor rewards for
     */
    function updateContributorRewards(address contributor) public {
        uint moarSpeed = moarContributorSpeeds[contributor];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, lastContributorBlock[contributor]);
        if (deltaBlocks > 0 && moarSpeed > 0) {
            uint newAccrued = mul_(deltaBlocks, moarSpeed);
            uint contributorAccrued = add_(moarAccrued[contributor], newAccrued);

            moarAccrued[contributor] = contributorAccrued;
            lastContributorBlock[contributor] = blockNumber;
        }
    }

    /**
     * @notice Claim all the MOAR accrued by holder in all markets
     * @param holder The address to claim MOAR for
     */
    function claimMoarReward(address holder) public {
        return claimMoar(holder, allMarkets);
    }

    function updateMoarReward(address holder) public returns (uint256){
        address[] memory holders = new address[](1);
        holders[0] = holder;
        updateClaimMoar(holders, allMarkets, true, true);
        return moarAccrued[holder];
    }

    /**
     * @notice Claim all the MOAR accrued by holder in the specified markets
     * @param holder The address to claim MOAR for
     * @param mTokens The list of markets to claim MOAR in
     */
    function claimMoar(address holder, MToken[] memory mTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimMoar(holders, mTokens, true, true);
    }

    function updateClaimMoar(address[] memory holders, MToken[] memory mTokens, bool borrowers, bool suppliers) public {
        for (uint i = 0; i < mTokens.length; i++) {
            MToken mToken = mTokens[i];
            require(markets[address(mToken)].isListed, "market not listed");
            if (borrowers == true) {
                Exp memory borrowIndex = Exp({mantissa: mToken.borrowIndex()});
                updateMoarBorrowIndex(address(mToken), borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerMoar(address(mToken), holders[j], borrowIndex);
                }
            }
            if (suppliers == true) {
                updateMoarSupplyIndex(address(mToken));
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierMoar(address(mToken), holders[j]);
                }
            }
        }
    }

    /**
     * @notice Claim all MOAR accrued by the holders
     * @param holders The addresses to claim MOAR for
     * @param mTokens The list of markets to claim MOAR in
     * @param borrowers Whether or not to claim MOAR earned by borrowing
     * @param suppliers Whether or not to claim MOAR earned by supplying
     */
    function claimMoar(address[] memory holders, MToken[] memory mTokens, bool borrowers, bool suppliers) public {
        require(rewardClaimEnabled, "disabled");
        updateClaimMoar(holders, mTokens, borrowers, suppliers);
        for (uint j = 0; j < holders.length; j++) {
            moarAccrued[holders[j]] = grantMoarInternal(holders[j], moarAccrued[holders[j]]);
        }
    }

    /**
     * @notice Transfer MOAR to the user
     * @dev Note: If there is not enough MOAR, we do not perform the transfer all.
     * @param user The address of the user to transfer MOAR to
     * @param amount The amount of MOAR to (possibly) transfer
     * @return The amount of MOAR which was NOT transferred to the user
     */
    function grantMoarInternal(address user, uint amount) internal returns (uint) {
        EIP20Interface moar = EIP20Interface(getMoarAddress());
        uint moarRemaining = moar.balanceOf(address(this));
        if (amount > 0 && amount <= moarRemaining) {
            moar.approve(mProxy, amount);
            MProxyInterface(mProxy).proxyClaimReward(getMoarAddress(), user, amount);
            return 0;
        }
        return amount;
    }

    /*** MOAR Distribution Admin ***/

    /**
     * @notice Transfer MOAR to the recipient
     * @dev Note: If there is not enough MOAR, we do not perform the transfer all.
     * @param recipient The address of the recipient to transfer MOAR to
     * @param amount The amount of MOAR to (possibly) transfer
     */
    function _grantMoar(address recipient, uint amount) public {
        require(adminOrInitializing(), "only admin");
        uint amountLeft = grantMoarInternal(recipient, amount);
        require(amountLeft == 0, "insufficient MOAR");
        emit MoarGranted(recipient, amount);
    }

    /**
     * @notice Set MOAR speed for a single market
     * @param mToken The market whose MOAR speed to update
     * @param moarSpeed New MOAR speed for market
     */
    function _setMoarSpeed(MToken mToken, uint moarSpeed) public {
        require(adminOrInitializing(), "only admin");
        setMoarSpeedInternal(mToken, moarSpeed);
    }

    /**
     * @notice Set MOAR speed for a single contributor
     * @param contributor The contributor whose MOAR speed to update
     * @param moarSpeed New MOAR speed for contributor
     */
    function _setContributorMoarSpeed(address contributor, uint moarSpeed) public {
        require(adminOrInitializing(), "only admin");

        // note that MOAR speed could be set to 0 to halt liquidity rewards for a contributor
        updateContributorRewards(contributor);
        if (moarSpeed == 0) {
            // release storage
            delete lastContributorBlock[contributor];
        } else {
            lastContributorBlock[contributor] = getBlockNumber();
        }
        moarContributorSpeeds[contributor] = moarSpeed;

        emit ContributorMoarSpeedUpdated(contributor, moarSpeed);
    }

    /**
     * @notice Set liquidity math model implementation
     * @param mathModel the math model implementation
     */
    function _setLiquidityMathModel(LiquidityMathModelInterface mathModel) public {
        require(msg.sender == admin, "only admin");

        LiquidityMathModelInterface oldLiquidityMathModel = liquidityMathModel;
        liquidityMathModel = mathModel;

        emit NewLiquidityMathModel(address(oldLiquidityMathModel), address(liquidityMathModel));
    }

    /**
     * @notice Set liquidation model implementation
     * @param newLiquidationModel the liquidation model implementation
     */
    function _setLiquidationModel(LiquidationModelInterface newLiquidationModel) public {
        require(msg.sender == admin, "only admin");

        LiquidationModelInterface oldLiquidationModel = liquidationModel;
        liquidationModel = newLiquidationModel;

        emit NewLiquidationModel(address(oldLiquidationModel), address(liquidationModel));
    }


    function _setMoarToken(address moarTokenAddress) public {
        require(msg.sender == admin, "only admin ");
        moarToken = moarTokenAddress;
    }

    function _setMProxy(address mProxyAddress) public {
        require(msg.sender == admin, "only admin");
        mProxy = mProxyAddress;
    }

    /**
     * @notice Add new privileged address 
     * @param privilegedAddress address to add
     */
    function _addPrivilegedAddress(address privilegedAddress) public {
        require(msg.sender == admin, "only admin");
        privilegedAddresses[privilegedAddress] = 1;
    }

    /**
     * @notice Remove privileged address 
     * @param privilegedAddress address to remove
     */
    function _removePrivilegedAddress(address privilegedAddress) public {
        require(msg.sender == admin, "only admin");
        delete privilegedAddresses[privilegedAddress];
    }

    /**
     * @notice Check if address if privileged
     * @param privilegedAddress address to check
     */
    function isPrivilegedAddress(address privilegedAddress) public view returns (bool) {
        return privilegedAddresses[privilegedAddress] == 1;
    }
    
    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (MToken[] memory) {
        return allMarkets;
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    /**
     * @notice Return the address of the MOAR token
     * @return The address of MOAR
     */
    function getMoarAddress() public view returns (address) {
        return moarToken;
    }

    function getContractVersion() external override pure returns(string memory){
        return "V1";
    }
}
