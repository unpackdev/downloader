// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./SafeCast.sol";

import "./MToken.sol";
import "./SupervisorInterface.sol";
import "./SupervisorStorage.sol";
import "./Mnt.sol";

/**
 * @title Minterest Supervisor Contract
 * @author Minterest
 */
contract Supervisor is SupervisorV1Storage, SupervisorInterface {
    using SafeCast for uint256;

    /// @notice Emitted when an admin supports a market
    event MarketListed(MToken mToken);

    /// @notice Emitted when an account enable a market
    event MarketEnabledAsCollateral(MToken mToken, address account);

    /// @notice Emitted when an account disable a market
    event MarketDisabledAsCollateral(MToken mToken, address account);

    /// @notice Emitted when a utilisation factor is changed by admin
    event NewUtilisationFactor(
        MToken mToken,
        uint256 oldUtilisationFactorMantissa,
        uint256 newUtilisationFactorMantissa
    );

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when buyback is changed
    event NewBuyback(Buyback oldBuyback, Buyback newBuyback);

    /// @notice Emitted when EmissionBooster contract is installed
    event NewEmissionBooster(EmissionBooster emissionBooster);

    /// @notice Emitted when Business Development System contract is installed
    event NewBusinessDevelopmentSystem(BDSystem oldBDSystem, BDSystem newBDSystem);

    /// @notice Event emitted when whitelist is changed
    event NewWhitelist(WhitelistInterface oldWhitelist, WhitelistInterface newWhitelist);

    /// @notice Emitted when liquidator is changed
    event NewLiquidator(Liquidation oldLiquidator, Liquidation newLiquidator);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event MarketActionPaused(MToken mToken, string action, bool pauseState);

    /// @notice Emitted when a new supply MNT emission rate is calculated for a market
    event MntSupplyEmissionRateUpdated(MToken indexed mToken, uint256 newSupplyEmissionRate);

    /// @notice Emitted when a new borrow MNT emission rate is calculated for a market
    event MntBorrowEmissionRateUpdated(MToken indexed mToken, uint256 newBorrowEmissionRate);

    /// @notice Emitted when liquidation fee is changed by admin
    event NewLiquidationFee(MToken marketAddress, uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /// @notice Emitted when MNT is distributed to a supplier
    event DistributedSupplierMnt(
        MToken indexed mToken,
        address indexed supplier,
        uint256 mntDelta,
        uint256 mntSupplyIndex
    );

    /// @notice Emitted when MNT is distributed to a borrower
    event DistributedBorrowerMnt(
        MToken indexed mToken,
        address indexed borrower,
        uint256 mntDelta,
        uint256 mntBorrowIndex
    );

    /// @notice Emitted when MNT is withdrew to a holder
    event WithdrawnMnt(address indexed holder, uint256 withdrewAmount);

    /// @notice Emitted when MNT is distributed to a business development representative
    event DistributedRepresentativeMnt(MToken indexed mToken, address indexed representative, uint256 mntDelta);

    /// @notice Emitted when borrow cap for a mToken is changed
    event NewBorrowCap(MToken indexed mToken, uint256 newBorrowCap);

    /// @notice Emitted when MNT is granted by admin
    event MntGranted(address recipient, uint256 amount);

    /// @notice Emitted when withdraw allowance changed
    event WithdrawAllowanceChanged(address owner, address withdrawer, bool allowed);

    /// @notice The initial MNT index for a market
    uint224 public constant mntInitialIndex = 1e36;

    // No utilisationFactorMantissa may exceed this value
    uint256 public constant utilisationFactorMaxMantissa = 0.9e18; // 0.9

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    function initialize(address admin_) external {
        require(initializedVersion == 0, ErrorCodes.SECOND_INITIALIZATION);
        initializedVersion = 1;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(TIMELOCK, admin_);
    }

    /***  Manage your collateral assets ***/

    /**
     * @notice Returns the assets an account has enabled as collateral
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has enabled as collateral
     */
    function getAccountAssets(address account) external view returns (MToken[] memory) {
        return accountAssets[account];
    }

    /**
     * @notice Returns whether the given account is enabled as collateral in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, MToken mToken) external view returns (bool) {
        return markets[address(mToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param mTokens The list of addresses of the mToken markets to be enabled as collateral
     */
    function enableAsCollateral(address[] memory mTokens) external override {
        uint256 len = mTokens.length;
        for (uint256 i = 0; i < len; i++) {
            enableMarketAsCollateralInternal(MToken(mTokens[i]), msg.sender);
        }
    }

    /**
     * @dev Add the market to the borrower's "assets in" for liquidity calculations
     * @param mToken The market to enable as collateral
     * @param account The address of the account to modify
     */
    function enableMarketAsCollateralInternal(MToken mToken, address account) internal {
        Market storage marketToEnableAsCollateral = markets[address(mToken)];
        require(marketToEnableAsCollateral.isListed, ErrorCodes.MARKET_NOT_LISTED);

        if (marketToEnableAsCollateral.accountMembership[account]) {
            return; // already joined
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if particular market is enabled for an account
        marketToEnableAsCollateral.accountMembership[account] = true;
        accountAssets[account].push(mToken);

        emit MarketEnabledAsCollateral(mToken, account);
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param mTokenAddress The address of the asset to be removed
     */
    function disableAsCollateral(address mTokenAddress) external override {
        MToken mToken = MToken(mTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the mToken */
        (uint256 tokensHeld, uint256 amountOwed, ) = mToken.getAccountSnapshot(msg.sender);

        /* Fail if the sender has a borrow balance */
        require(amountOwed == 0, ErrorCodes.BALANCE_OWED);

        /* Fail if the sender is not permitted to redeem all of their tokens */
        beforeRedeemInternal(mTokenAddress, msg.sender, tokensHeld);

        Market storage marketToDisable = markets[address(mToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToDisable.accountMembership[msg.sender]) {
            return;
        }

        /* Set mToken account membership to false */
        delete marketToDisable.accountMembership[msg.sender];

        /* Delete mToken from the account’s list of assets */
        // load into memory for faster iteration
        MToken[] memory accountAssetList = accountAssets[msg.sender];
        uint256 len = accountAssetList.length;
        uint256 assetIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (accountAssetList[i] == mToken) {
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

        emit MarketDisabledAsCollateral(mToken, msg.sender);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Makes checks if the account should be allowed to lend tokens in the given market
     * @param mToken The market to verify the lend against
     * @param lender The account which would get the lent tokens
     * @param wrapBalance Wrap balance of lender account before lend
     */
    // slither-disable-next-line reentrancy-benign
    function beforeLend(
        address mToken,
        address lender,
        uint256 wrapBalance
    ) external override whitelistMode(lender) {
        // Bells and whistles to notify user - operation is paused.
        require(!lendKeeperPaused[mToken], ErrorCodes.OPERATION_PAUSED);
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        if (wrapBalance == 0) {
            enableMarketAsCollateralInternal(MToken(mToken), lender);
        }

        // Trigger Emission system
        updateMntSupplyIndex(mToken);
        //slither-disable-next-line reentrancy-events
        distributeSupplierMnt(mToken, lender);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market and triggers emission system
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     */
    //slither-disable-next-line reentrancy-benign
    function beforeRedeem(
        address mToken,
        address redeemer,
        uint256 redeemTokens
    ) external override nonReentrant whitelistMode(redeemer) {
        beforeRedeemInternal(mToken, redeemer, redeemTokens);

        // Trigger Emission system
        //slither-disable-next-line reentrancy-events
        updateMntSupplyIndex(mToken);
        distributeSupplierMnt(mToken, redeemer);
    }

    /**
     * @dev Checks if the account should be allowed to redeem tokens in the given market
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     */
    function beforeRedeemInternal(
        address mToken,
        address redeemer,
        uint256 redeemTokens
    ) internal view {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[mToken].accountMembership[redeemer]) {
            return;
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (, uint256 shortfall) = getHypotheticalAccountLiquidity(redeemer, MToken(mToken), redeemTokens, 0);
        require(shortfall <= 0, ErrorCodes.INSUFFICIENT_LIQUIDITY);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(uint256 redeemAmount, uint256 redeemTokens) external pure override {
        // Require tokens is zero or amount is also zero
        require(redeemTokens > 0 || redeemAmount == 0, ErrorCodes.INVALID_REDEEM);
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param mToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     */
    //slither-disable-next-line reentrancy-benign
    function beforeBorrow(
        address mToken,
        address borrower,
        uint256 borrowAmount
    ) external override nonReentrant whitelistMode(borrower) {
        // Bells and whistles to notify user - operation is paused.
        require(!borrowKeeperPaused[mToken], ErrorCodes.OPERATION_PAUSED);
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        if (!markets[mToken].accountMembership[borrower]) {
            // only mTokens may call beforeBorrow if borrower not in market
            require(msg.sender == mToken, ErrorCodes.INVALID_SENDER);

            // attempt to enable market for the borrower
            enableMarketAsCollateralInternal(MToken(msg.sender), borrower);

            // it should be impossible to break the important invariant
            assert(markets[mToken].accountMembership[borrower]);
        }

        require(oracle.getUnderlyingPrice(MToken(mToken)) > 0, ErrorCodes.INVALID_PRICE);

        uint256 borrowCap = borrowCaps[mToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 totalBorrows = MToken(mToken).totalBorrows();
            uint256 nextTotalBorrows = totalBorrows + borrowAmount;
            require(nextTotalBorrows < borrowCap, ErrorCodes.BORROW_CAP_REACHED);
        }

        (, uint256 shortfall) = getHypotheticalAccountLiquidity(borrower, MToken(mToken), 0, borrowAmount);
        require(shortfall <= 0, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        // Trigger Emission system
        uint224 borrowIndex = MToken(mToken).borrowIndex().toUint224();
        //slither-disable-next-line reentrancy-events
        updateMntBorrowIndex(mToken, borrowIndex);
        distributeBorrowerMnt(mToken, borrower, borrowIndex);
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param mToken The market to verify the repay against
     * @param borrower The account which would borrowed the asset
     */
    //slither-disable-next-line reentrancy-benign
    function beforeRepayBorrow(address mToken, address borrower)
        external
        override
        nonReentrant
        whitelistMode(borrower)
    {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        // Trigger Emission system
        uint224 borrowIndex = MToken(mToken).borrowIndex().toUint224();
        //slither-disable-next-line reentrancy-events
        updateMntBorrowIndex(mToken, borrowIndex);
        distributeBorrowerMnt(mToken, borrower, borrowIndex);
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur (auto liquidation process)
     * @param mToken Asset which was used as collateral and will be seized
     * @param liquidator_ The address of liquidator contract
     * @param borrower The address of the borrower
     */
    //slither-disable-next-line reentrancy-benign
    function beforeAutoLiquidationSeize(
        address mToken,
        address liquidator_,
        address borrower
    ) external override nonReentrant {
        isLiquidator(liquidator_);
        // Trigger Emission system
        //slither-disable-next-line reentrancy-events
        updateMntSupplyIndex(mToken);
        distributeSupplierMnt(mToken, borrower);
    }

    /**
     * @notice Checks if the address is the Liquidation contract
     * @dev Used in liquidation process
     * @param liquidator_ Prospective address of the Liquidation contract
     */
    function isLiquidator(address liquidator_) public view override {
        require(liquidator == Liquidation(liquidator_), ErrorCodes.UNRELIABLE_LIQUIDATOR);
    }

    /**
     * @notice Checks if the sender should be allowed to repay borrow in the given market (auto liquidation process)
     * @param liquidator_ The address of liquidator contract
     * @param borrower_ The account which borrowed the asset
     * @param mToken_ The market to verify the repay against
     * @param borrowIndex_ Accumulator of the total earned interest rate since the opening of the market
     */
    //slither-disable-next-line reentrancy-benign
    function beforeAutoLiquidationRepay(
        address liquidator_,
        address borrower_,
        address mToken_,
        uint224 borrowIndex_
    ) external override nonReentrant {
        isLiquidator(liquidator_);
        //slither-disable-next-line reentrancy-events
        updateMntBorrowIndex(mToken_, borrowIndex_);
        distributeBorrowerMnt(mToken_, borrower_, borrowIndex_);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param mToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of mTokens to transfer
     */
    //slither-disable-next-line reentrancy-benign,reentrancy-no-eth
    function beforeTransfer(
        address mToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external override nonReentrant {
        // Bells and whistles to notify user - operation is paused.
        require(!transferKeeperPaused, ErrorCodes.OPERATION_PAUSED);

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        beforeRedeemInternal(mToken, src, transferTokens);

        // Trigger Emission system
        //slither-disable-next-line reentrancy-events
        updateMntSupplyIndex(mToken);
        distributeSupplierMnt(mToken, src);
        distributeSupplierMnt(mToken, dst);
    }

    /**
     * @notice Makes checks before flash loan in MToken
     * @param mToken The address of the token
     * receiver - The address of the loan receiver
     * amount - How much tokens to flash loan
     * fee - Flash loan fee
     */
    function beforeFlashLoan(
        address mToken,
        address, /* receiver */
        uint256, /* amount */
        uint256 /* fee */
    ) external view override {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(!flashLoanKeeperPaused[mToken], ErrorCodes.OPERATION_PAUSED);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `mTokenBalance` is the number of mTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 mTokenBalance;
        uint256 borrowBalance;
        uint256 utilisationFactor;
        uint256 exchangeRate;
        uint256 oraclePrice;
        uint256 tokensToDenom;
    }

    /**
     * @notice Calculate account liquidity in USD related to utilisation factors of underlying assets
     * @return (USD value above total utilisation requirements of all assets,
     *           USD value below total utilisation requirements of all assets)
     */
    function getAccountLiquidity(address account) external view returns (uint256, uint256) {
        return getHypotheticalAccountLiquidity(account, MToken(address(0)), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param mTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        MToken mTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) public view returns (uint256, uint256) {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results

        // For each asset the account is in
        MToken[] memory assets = accountAssets[account];
        for (uint256 i = 0; i < assets.length; i++) {
            MToken asset = assets[i];

            // Read the balances and exchange rate from the mToken
            //slither-disable-next-line calls-loop
            (vars.mTokenBalance, vars.borrowBalance, vars.exchangeRate) = asset.getAccountSnapshot(account);
            vars.utilisationFactor = markets[address(asset)].utilisationFactorMantissa;

            // Get the normalized price of the asset
            //slither-disable-next-line calls-loop
            vars.oraclePrice = oracle.getUnderlyingPrice(asset);
            require(vars.oraclePrice > 0, ErrorCodes.INVALID_PRICE);

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom =
                (((vars.utilisationFactor * vars.exchangeRate) / EXP_SCALE) * vars.oraclePrice) /
                EXP_SCALE;

            // sumCollateral += tokensToDenom * mTokenBalance
            vars.sumCollateral += (vars.tokensToDenom * vars.mTokenBalance) / EXP_SCALE;

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects += (vars.oraclePrice * vars.borrowBalance) / EXP_SCALE;

            // Calculate effects of interacting with mTokenModify
            if (asset == mTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects += (vars.tokensToDenom * redeemTokens) / EXP_SCALE;

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects += (vars.oraclePrice * borrowAmount) / EXP_SCALE;
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Get liquidationFeeMantissa and utilisationFactorMantissa for market
     * @param market Market for which values are obtained
     * @return (liquidationFeeMantissa, utilisationFactorMantissa)
     */
    function getMarketData(MToken market) external view returns (uint256, uint256) {
        return (markets[address(market)].liquidationFeeMantissa, markets[address(market)].utilisationFactorMantissa);
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new price oracle for the supervisor
     * @dev Admin function to set a new price oracle
     */
    function setPriceOracle(PriceOracle newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PriceOracle oldOracle = oracle;
        oracle = newOracle;
        emit NewPriceOracle(oldOracle, newOracle);
    }

    /**
     * @notice Sets a new buyback for the supervisor
     * @dev Admin function to set a new buyback
     */
    function setBuyback(Buyback newBuyback) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Buyback oldBuyback = buyback;
        buyback = newBuyback;
        emit NewBuyback(oldBuyback, newBuyback);
    }

    /**
     * @notice Sets a new emissionBooster for the supervisor
     * @dev Admin function to set a new EmissionBooster. Can only be installed once.
     */
    function setEmissionBooster(EmissionBooster _emissionBooster) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(Address.isContract(address(_emissionBooster)), ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE);
        require(address(emissionBooster) == address(0), ErrorCodes.CONTRACT_ALREADY_SET);
        emissionBooster = _emissionBooster;
        emit NewEmissionBooster(emissionBooster);
    }

    /// @notice function to set BDSystem contract
    /// @param newBDSystem_ new Business Development system contract address
    function setBDSystem(BDSystem newBDSystem_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BDSystem oldBDSystem = bdSystem;
        bdSystem = newBDSystem_;
        emit NewBusinessDevelopmentSystem(oldBDSystem, newBDSystem_);
    }

    /*
     * @notice Sets a new whitelist for the supervisor
     * @dev Admin function to set a new whitelist
     */
    function setWhitelist(WhitelistInterface newWhitelist_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        WhitelistInterface oldWhitelist = whitelist;
        whitelist = newWhitelist_;
        emit NewWhitelist(oldWhitelist, newWhitelist_);
    }

    /**
     * @notice Sets a new liquidator for the supervisor
     * @dev Admin function to set a new liquidation contract
     */
    function setLiquidator(Liquidation newLiquidator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Liquidation oldLiquidator = liquidator;
        liquidator = newLiquidator;
        emit NewLiquidator(oldLiquidator, newLiquidator);
    }

    /**
     * @notice Sets the utilisationFactor for a market
     * @dev Admin function to set per-market utilisationFactor
     * @param mToken The market to set the factor on
     * @param newUtilisationFactorMantissa The new utilisation factor, scaled by 1e18
     */
    function setUtilisationFactor(MToken mToken, uint256 newUtilisationFactorMantissa) external onlyRole(TIMELOCK) {
        Market storage market = markets[address(mToken)];
        require(market.isListed, ErrorCodes.MARKET_NOT_LISTED);

        // Check utilisation factor <= 0.9
        require(
            newUtilisationFactorMantissa <= utilisationFactorMaxMantissa,
            ErrorCodes.INVALID_UTILISATION_FACTOR_MANTISSA
        );

        // If utilisation factor = 0 than price can be any. Otherwise price must be > 0.
        require(newUtilisationFactorMantissa == 0 || oracle.getUnderlyingPrice(mToken) > 0, ErrorCodes.INVALID_PRICE);

        // Set market's utilisation factor to new utilisation factor, remember old value
        uint256 oldUtilisationFactorMantissa = market.utilisationFactorMantissa;
        market.utilisationFactorMantissa = newUtilisationFactorMantissa;

        // Emit event with asset, old utilisation factor, and new utilisation factor
        emit NewUtilisationFactor(mToken, oldUtilisationFactorMantissa, newUtilisationFactorMantissa);
    }

    /**
     * @notice Sets the liquidationFee for a market
     * @dev Admin function to set per-market liquidationFee
     * @param mToken The market to set the fee on
     * @param newLiquidationFeeMantissa The new liquidation fee, scaled by 1e18
     */
    function setLiquidationFee(MToken mToken, uint256 newLiquidationFeeMantissa) external onlyRole(TIMELOCK) {
        require(newLiquidationFeeMantissa > 0, ErrorCodes.LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO);

        Market storage market = markets[address(mToken)];
        require(market.isListed, ErrorCodes.MARKET_NOT_LISTED);

        uint256 oldLiquidationFeeMantissa = market.liquidationFeeMantissa;
        market.liquidationFeeMantissa = newLiquidationFeeMantissa;

        emit NewLiquidationFee(mToken, oldLiquidationFeeMantissa, newLiquidationFeeMantissa);
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed, also initialize MNT market state.
     * @dev Admin function to set isListed and add support for the market
     * @param mToken The address of the market (token) to list
     */
    function supportMarket(MToken mToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            mToken.supportsInterface(type(MTokenInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );
        require(!markets[address(mToken)].isListed, ErrorCodes.MARKET_ALREADY_LISTED);

        markets[address(mToken)].isListed = true;
        markets[address(mToken)].utilisationFactorMantissa = 0;
        markets[address(mToken)].liquidationFeeMantissa = 0;
        allMarkets.push(mToken);

        // Initialize supplyState and borrowState for market
        MntMarketState storage supplyState = mntSupplyState[address(mToken)];
        MntMarketState storage borrowState = mntBorrowState[address(mToken)];

        // Update market state indices
        if (supplyState.index == 0) {
            // Initialize supply state index with default value
            supplyState.index = mntInitialIndex;
        }

        if (borrowState.index == 0) {
            // Initialize borrow state index with default value
            borrowState.index = mntInitialIndex;
        }

        // Update market state block numbers
        supplyState.block = borrowState.block = uint32(getBlockNumber());

        emit MarketListed(mToken);
    }

    /**
     * @notice Set the given borrow caps for the given mToken markets.
     *         Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or gateKeeper function to set the borrow caps.
     *      A borrow cap of 0 corresponds to unlimited borrowing.
     * @param mTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set.
     *                      A value of 0 corresponds to unlimited borrowing.
     */
    function setMarketBorrowCaps(MToken[] calldata mTokens, uint256[] calldata newBorrowCaps)
        external
        onlyRole(GATEKEEPER)
    {
        uint256 numMarkets = mTokens.length;
        uint256 numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, ErrorCodes.INVALID_MTOKENS_OR_BORROW_CAPS);

        for (uint256 i = 0; i < numMarkets; i++) {
            borrowCaps[address(mTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(mTokens[i], newBorrowCaps[i]);
        }
    }

    function setLendPaused(MToken mToken, bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(markets[address(mToken)].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        lendKeeperPaused[address(mToken)] = state;
        emit MarketActionPaused(mToken, "Lend", state);
        return state;
    }

    function setBorrowPaused(MToken mToken, bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(markets[address(mToken)].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        borrowKeeperPaused[address(mToken)] = state;
        emit MarketActionPaused(mToken, "Borrow", state);
        return state;
    }

    function setFlashLoanPaused(MToken mToken, bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(markets[address(mToken)].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        flashLoanKeeperPaused[address(mToken)] = state;
        emit MarketActionPaused(mToken, "FlashLoan", state);
        return state;
    }

    function setTransferPaused(bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        transferKeeperPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function setWithdrawMntPaused(bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        withdrawMntKeeperPaused = state;
        emit ActionPaused("WithdrawMnt", state);
        return state;
    }

    /*** Mnt Distribution ***/

    /**
     * @dev Set MNT borrow and supply emission rates for a single market
     * @param mToken The market whose MNT emission rate to update
     * @param newMntSupplyEmissionRate New supply MNT emission rate for market
     * @param newMntBorrowEmissionRate New borrow MNT emission rate for market
     */
    //slither-disable-next-line reentrancy-no-eth
    function setMntEmissionRates(
        MToken mToken,
        uint256 newMntSupplyEmissionRate,
        uint256 newMntBorrowEmissionRate
    ) external onlyRole(TIMELOCK) nonReentrant {
        Market storage market = markets[address(mToken)];
        require(market.isListed, ErrorCodes.MARKET_NOT_LISTED);
        if (mntSupplyEmissionRate[address(mToken)] != newMntSupplyEmissionRate) {
            // Supply emission rate updated so let's update supply state to ensure that
            //  1. MNT accrued properly for the old emission rate.
            //  2. MNT accrued at the new speed starts after this block.
            //slither-disable-next-line reentrancy-events
            updateMntSupplyIndex(address(mToken));

            // Update emission rate and emit event
            mntSupplyEmissionRate[address(mToken)] = newMntSupplyEmissionRate;
            emit MntSupplyEmissionRateUpdated(mToken, newMntSupplyEmissionRate);
        }

        if (mntBorrowEmissionRate[address(mToken)] != newMntBorrowEmissionRate) {
            // Borrow emission rate updated so let's update borrow state to ensure that
            //  1. MNT accrued properly for the old emission rate.
            //  2. MNT accrued at the new speed starts after this block.
            uint224 borrowIndex = mToken.borrowIndex().toUint224();
            updateMntBorrowIndex(address(mToken), borrowIndex);

            // Update emission rate and emit event
            mntBorrowEmissionRate[address(mToken)] = newMntBorrowEmissionRate;
            emit MntBorrowEmissionRateUpdated(mToken, newMntBorrowEmissionRate);
        }
    }

    /**
     * @dev Calculates the new state of the market.
     * @param state The block number the index was last updated at and the market's last updated mntBorrowIndex
     * or mntSupplyIndex in this block
     * @param emissionRate MNT rate that each market currently receives (supply or borrow)
     * @param totalBalance Total market balance (totalSupply or totalBorrow)
     * Note: this method doesn't return anything, it only mutates memory variable `state`.
     */
    function calculateUpdatedMarketState(
        MntMarketState memory state,
        uint256 emissionRate,
        uint256 totalBalance
    ) internal view {
        uint256 blockNumber = getBlockNumber();

        if (emissionRate > 0) {
            uint256 deltaBlocks = blockNumber - state.block;
            uint256 mntAccrued_ = deltaBlocks * emissionRate;
            uint256 ratio = totalBalance > 0 ? (mntAccrued_ * DOUBLE_SCALE) / totalBalance : 0;
            // index = lastUpdatedIndex + deltaBlocks * emissionRate / amount
            state.index += ratio.toUint224();
        }

        state.block = uint32(blockNumber);
    }

    /**
     * @dev Gets current market state (the block number and MNT supply index)
     * @param mToken The market whose MNT supply index to get
     */
    function getUpdatedMntSupplyIndex(address mToken) internal view returns (MntMarketState memory supplyState) {
        supplyState = mntSupplyState[mToken];
        //slither-disable-next-line calls-loop
        calculateUpdatedMarketState(supplyState, mntSupplyEmissionRate[mToken], MToken(mToken).totalSupply());
        return supplyState;
    }

    /**
     * @dev Gets current market state (the block number and MNT supply index)
     * @param mToken The market whose MNT supply index to get
     */
    function getUpdatedMntBorrowIndex(address mToken, uint224 marketBorrowIndex)
        internal
        view
        returns (MntMarketState memory borrowState)
    {
        borrowState = mntBorrowState[mToken];
        //slither-disable-next-line calls-loop
        uint256 borrowAmount = (MToken(mToken).totalBorrows() * EXP_SCALE) / marketBorrowIndex;
        calculateUpdatedMarketState(borrowState, mntBorrowEmissionRate[mToken], borrowAmount);
        return borrowState;
    }

    /**
     * @dev Accrue MNT to the market by updating the MNT supply index.
     * Index is a cumulative sum of the MNT per mToken accrued.
     * @param mToken The market whose MNT supply index to update
     */
    function updateMntSupplyIndex(address mToken) internal {
        uint32 lastUpdatedBlock = mntSupplyState[mToken].block;
        /* Short-circuit. Indexes already updated */
        //slither-disable-next-line incorrect-equality
        if (lastUpdatedBlock == getBlockNumber()) return;

        //slither-disable-next-line calls-loop
        if (emissionBooster != EmissionBooster(address(0)) && emissionBooster.isEmissionBoostingEnabled()) {
            uint224 lastUpdatedIndex = mntSupplyState[mToken].index;
            MntMarketState memory currentState = getUpdatedMntSupplyIndex(mToken);
            mntSupplyState[mToken] = currentState;
            //slither-disable-next-line calls-loop
            emissionBooster.updateSupplyIndexesHistory(
                MToken(mToken),
                lastUpdatedBlock,
                lastUpdatedIndex,
                currentState.index
            );
        } else {
            mntSupplyState[mToken] = getUpdatedMntSupplyIndex(mToken);
        }
    }

    /**
     * @dev Accrue MNT to the market by updating the MNT borrow index.
     * Index is a cumulative sum of the MNT per mToken accrued.
     * @param mToken The market whose MNT borrow index to update
     * @param marketBorrowIndex The market's last updated BorrowIndex
     */
    function updateMntBorrowIndex(address mToken, uint224 marketBorrowIndex) internal {
        uint32 lastUpdatedBlock = mntBorrowState[mToken].block;
        /* Short-circuit. Indexes already updated */
        //slither-disable-next-line incorrect-equality
        if (lastUpdatedBlock == getBlockNumber()) return;

        //slither-disable-next-line calls-loop
        if (emissionBooster != EmissionBooster(address(0)) && emissionBooster.isEmissionBoostingEnabled()) {
            uint224 lastUpdatedIndex = mntBorrowState[mToken].index;
            MntMarketState memory currentState = getUpdatedMntBorrowIndex(mToken, marketBorrowIndex);
            mntBorrowState[mToken] = currentState;
            //slither-disable-next-line calls-loop
            emissionBooster.updateBorrowIndexesHistory(
                MToken(mToken),
                lastUpdatedBlock,
                lastUpdatedIndex,
                currentState.index
            );
        } else {
            mntBorrowState[mToken] = getUpdatedMntBorrowIndex(mToken, marketBorrowIndex);
        }
    }

    /**
     * @notice Accrues MNT to the market by updating the borrow and supply indexes
     * @dev This method doesn't update MNT index history in Minterest NFT.
     * @param market The market whose supply and borrow index to update
     * @return (MNT supply index, MNT borrow index)
     */
    function updateAndGetMntIndexes(MToken market) external returns (uint224, uint224) {
        MntMarketState memory supplyState = getUpdatedMntSupplyIndex(address(market));
        mntSupplyState[address(market)] = supplyState;

        uint224 borrowIndex = market.borrowIndex().toUint224();
        MntMarketState memory borrowState = getUpdatedMntBorrowIndex(address(market), borrowIndex);
        mntBorrowState[address(market)] = borrowState;

        return (supplyState.index, borrowState.index);
    }

    /**
     * @dev Calculate MNT accrued by a supplier. The calculation takes into account business development system and
     * NFT emission boosts. NFT emission boost doesn't work with liquidity provider emission boost at the same time.
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute MNT to
     */
    //slither-disable-next-line reentrancy-benign,reentrancy-events
    function distributeSupplierMnt(address mToken, address supplier) internal {
        uint32 currentBlock = uint32(getBlockNumber());
        uint224 supplyIndex = mntSupplyState[mToken].index;
        uint32 supplierLastUpdatedBlock = mntSupplierState[mToken][supplier].block;
        uint224 supplierIndex = mntSupplierState[mToken][supplier].index;

        if (supplierIndex == 0 && supplyIndex >= mntInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with MNT accrued from the start of when supplier rewards were first
            // set for the market.
            supplierIndex = mntInitialIndex;
            supplierLastUpdatedBlock = currentBlock;
        }

        // Update supplier's index and block to the current index and block since we are distributing accrued MNT
        mntSupplierState[mToken][supplier] = MntMarketAccountState({index: supplyIndex, block: currentBlock});
        //slither-disable-next-line calls-loop
        uint256 supplierTokens = MToken(mToken).balanceOf(supplier);

        uint256 deltaIndex = supplyIndex - supplierIndex;
        address representative = address(0);
        uint256 representativeBonus = 0;
        uint256 deltaIndexBoost = 0;

        // Calculate change in the cumulative sum of the MNT per mToken accrued (with considering BD system boosts)
        if (address(bdSystem) != address(0)) {
            //slither-disable-next-line calls-loop
            (representative, representativeBonus, deltaIndexBoost) = bdSystem.calculateEmissionBoost(
                supplier,
                deltaIndex
            );
        }

        // Calculate change in the cumulative sum of the MNT per mToken accrued (with considering NFT emission boost).
        // NFT emission boost doesn't work with liquidity provider emission boost at the same time.
        // slither-disable-next-line incorrect-equality
        if (deltaIndexBoost == 0 && emissionBooster != EmissionBooster(address(0))) {
            //slither-disable-next-line calls-loop
            deltaIndexBoost = emissionBooster.calculateEmissionBoost(
                MToken(mToken),
                supplier,
                supplierIndex,
                supplierLastUpdatedBlock,
                supplyIndex,
                true
            );
        }

        uint256 accrueDelta = (supplierTokens * (deltaIndex + deltaIndexBoost)) / DOUBLE_SCALE;

        if (accrueDelta > 0) {
            mntAccrued[supplier] += accrueDelta;
            emit DistributedSupplierMnt(MToken(mToken), supplier, accrueDelta, supplyIndex);

            if (representative != address(0)) {
                uint256 representativeAccruedDelta = (accrueDelta * representativeBonus) / EXP_SCALE;
                mntAccrued[representative] += representativeAccruedDelta;
                emit DistributedRepresentativeMnt(MToken(mToken), representative, representativeAccruedDelta);
            }
        }
    }

    /**
     * @dev Calculate MNT accrued by a borrower. The calculation takes into account business development system and
     * NFT emission boosts. NFT emission boost doesn't work with liquidity provider emission boost at the same time.
     * Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute MNT to
     * @param marketBorrowIndex The market's last updated BorrowIndex
     */
    //slither-disable-next-line reentrancy-benign,reentrancy-events
    function distributeBorrowerMnt(
        address mToken,
        address borrower,
        uint224 marketBorrowIndex
    ) internal {
        uint32 currentBlock = uint32(getBlockNumber());
        uint224 borrowIndex = mntBorrowState[mToken].index;
        uint32 borrowerLastUpdatedBlock = mntBorrowerState[mToken][borrower].block;
        uint224 borrowerIndex = mntBorrowerState[mToken][borrower].index;

        if (borrowerIndex == 0 && borrowIndex >= mntInitialIndex) {
            // Covers the case where users borrowed tokens before the market's borrow state index was set.
            // Rewards the user with MNT accrued from the start of when borrower rewards were first
            // set for the market.
            borrowerIndex = mntInitialIndex;
            borrowerLastUpdatedBlock = currentBlock;
        }

        // Update supplier's index and block to the current index and block since we are distributing accrued MNT
        mntBorrowerState[mToken][borrower] = MntMarketAccountState({index: borrowIndex, block: currentBlock});
        //slither-disable-next-line calls-loop
        uint256 borrowerAmount = (MToken(mToken).borrowBalanceStored(borrower) * EXP_SCALE) / marketBorrowIndex;

        uint256 deltaIndex = borrowIndex - borrowerIndex;
        address representative = address(0);
        uint256 representativeBonus = 0;
        uint256 deltaIndexBoost = 0;

        // Calculate change in the cumulative sum of the MNT per mToken accrued (with considering BD system boosts)
        if (address(bdSystem) != address(0)) {
            //slither-disable-next-line calls-loop
            (representative, representativeBonus, deltaIndexBoost) = bdSystem.calculateEmissionBoost(
                borrower,
                deltaIndex
            );
        }

        // Calculate change in the cumulative sum of the MNT per mToken accrued (with considering NFT emission boost).
        // NFT emission boost doesn't work with liquidity provider emission boost at the same time.
        // slither-disable-next-line incorrect-equality
        if (deltaIndexBoost == 0 && emissionBooster != EmissionBooster(address(0))) {
            //slither-disable-next-line calls-loop
            deltaIndexBoost = emissionBooster.calculateEmissionBoost(
                MToken(mToken),
                borrower,
                borrowerIndex,
                borrowerLastUpdatedBlock,
                borrowIndex,
                false
            );
        }

        uint256 accrueDelta = (borrowerAmount * (deltaIndex + deltaIndexBoost)) / DOUBLE_SCALE;

        if (accrueDelta > 0) {
            mntAccrued[borrower] += accrueDelta;
            emit DistributedBorrowerMnt(MToken(mToken), borrower, accrueDelta, borrowIndex);

            if (representative != address(0)) {
                uint256 representativeAccruedDelta = (accrueDelta * representativeBonus) / EXP_SCALE;
                mntAccrued[representative] += representativeAccruedDelta;
                emit DistributedRepresentativeMnt(MToken(mToken), representative, representativeAccruedDelta);
            }
        }
    }

    /**
     * @notice Updates market indices and distributes tokens (if any) for holder
     * @dev Updates indices and distributes only for those markets where the holder have a
     * non-zero supply or borrow balance.
     * @param holder The address to distribute MNT for
     */
    function distributeAllMnt(address holder) external nonReentrant {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        return distributeMnt(holders, allMarkets, true, true);
    }

    /**
     * @notice Distribute all MNT accrued by the holders
     * @param holders The addresses to distribute MNT for
     * @param mTokens The list of markets to distribute MNT in
     * @param borrowers Whether or not to distribute MNT earned by borrowing
     * @param suppliers Whether or not to distribute MNT earned by supplying
     */
    //slither-disable-next-line reentrancy-no-eth
    function distributeMnt(
        address[] memory holders,
        MToken[] memory mTokens,
        bool borrowers,
        bool suppliers
    ) public {
        uint256 numberOfMTokens = mTokens.length;
        uint256 numberOfHolders = holders.length;

        for (uint256 i = 0; i < numberOfMTokens; i++) {
            MToken mToken = mTokens[i];
            require(markets[address(mToken)].isListed, ErrorCodes.MARKET_NOT_LISTED);

            for (uint256 j = 0; j < numberOfHolders; j++) {
                address holder = holders[j];
                if (borrowers) {
                    //slither-disable-next-line calls-loop
                    uint256 holderBorrowUnderlying = mToken.borrowBalanceStored(holder);
                    if (holderBorrowUnderlying > 0) {
                        //slither-disable-next-line calls-loop
                        uint224 borrowIndex = mToken.borrowIndex().toUint224();
                        //slither-disable-next-line reentrancy-events,reentrancy-benign
                        updateMntBorrowIndex(address(mToken), borrowIndex);
                        distributeBorrowerMnt(address(mToken), holders[j], borrowIndex);
                    }
                }

                if (suppliers) {
                    //slither-disable-next-line calls-loop
                    uint256 holderSupplyWrap = mToken.balanceOf(holder);
                    if (holderSupplyWrap > 0) {
                        updateMntSupplyIndex(address(mToken));
                        //slither-disable-next-line reentrancy-events,reentrancy-benign
                        distributeSupplierMnt(address(mToken), holder);
                    }
                }
            }
        }
    }

    /**
     * @param account The address of the account whose MNT are withdrawn
     * @param withdrawer The address of the withdrawer
     * @return true if `withdrawer` can withdraw MNT in behalf of `account`
     */
    function isWithdrawAllowed(address account, address withdrawer) public view returns (bool) {
        return withdrawAllowances[account][withdrawer];
    }

    /**
     * @notice Allow `withdrawer` to withdraw MNT on sender's behalf
     * @param withdrawer The address of the withdrawer
     */
    function allowWithdraw(address withdrawer) external {
        withdrawAllowances[msg.sender][withdrawer] = true;
        emit WithdrawAllowanceChanged(msg.sender, withdrawer, true);
    }

    /**
     * @notice Deny `withdrawer` from withdrawing MNT on sender's behalf
     * @param withdrawer The address of the withdrawer
     */
    function denyWithdraw(address withdrawer) external {
        withdrawAllowances[msg.sender][withdrawer] = false;
        emit WithdrawAllowanceChanged(msg.sender, withdrawer, false);
    }

    /**
     * @notice Withdraw mnt accrued by the holders for a given amounts
     * @dev If `amount_ == MaxUint256` withdraws all accrued MNT tokens.
     * @param holders The addresses to withdraw MNT for
     * @param amounts Amount of tokens to withdraw for every holder
     */
    function withdrawMnt(address[] memory holders, uint256[] memory amounts) external {
        require(!withdrawMntKeeperPaused, ErrorCodes.OPERATION_PAUSED);
        require(holders.length == amounts.length, ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL);

        // We are transferring MNT to the account. If there is not enough MNT, we do not perform the transfer all.
        // Also check withdrawal allowance
        for (uint256 j = 0; j < holders.length; j++) {
            address holder = holders[j];
            uint256 amount = amounts[j];
            require(holder == msg.sender || isWithdrawAllowed(holder, msg.sender), ErrorCodes.WITHDRAW_NOT_ALLOWED);
            if (amount == type(uint256).max) {
                amount = mntAccrued[holder];
            } else {
                require(amount <= mntAccrued[holder], ErrorCodes.INCORRECT_AMOUNT);
            }

            // slither-disable-next-line reentrancy-no-eth
            uint256 transferredAmount = amount - grantMntInternal(holder, amount);
            mntAccrued[holder] -= transferredAmount;
            //slither-disable-next-line reentrancy-events
            emit WithdrawnMnt(holder, transferredAmount);

            //slither-disable-next-line calls-loop
            if (buyback != Buyback(address(0))) buyback.restakeFor(holder);
        }
    }

    /**
     * @dev Transfer MNT to the account. If there is not enough MNT, we do not perform the transfer all.
     * @param account The address of the account to transfer MNT to
     * @param amount The amount of MNT to (possibly) transfer
     * @return The amount of MNT which was NOT transferred to the account
     */
    function grantMntInternal(address account, uint256 amount) internal returns (uint256) {
        Mnt mnt = Mnt(getMntAddress());
        //slither-disable-next-line calls-loop
        uint256 mntRemaining = mnt.balanceOf(address(this));
        if (amount > 0 && amount <= mntRemaining) {
            //slither-disable-next-line calls-loop
            require(mnt.transfer(account, amount));
            return 0;
        }
        return amount;
    }

    /*** Mnt Distribution Admin ***/

    /**
     * @notice Transfer MNT to the recipient
     * @dev Note: If there is not enough MNT, we do not perform the transfer all.
     * @param recipient The address of the recipient to transfer MNT to
     * @param amount The amount of MNT to (possibly) transfer
     */
    //slither-disable-next-line reentrancy-events
    function grantMnt(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 amountLeft = grantMntInternal(recipient, amount);
        require(amountLeft <= 0, ErrorCodes.INSUFFICIENT_MNT_FOR_GRANT);
        emit MntGranted(recipient, amount);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (MToken[] memory) {
        return allMarkets;
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(SupervisorInterface).interfaceId || super.supportsInterface(interfaceId);
    }

    function getBlockNumber() public view virtual returns (uint256) {
        return block.number;
    }

    /**
     * @notice Return the address of the MNT token
     * @return The address of MNT
     */
    function getMntAddress() public view virtual returns (address) {
        return 0x95966457BbAd4391EdaC349a43Db5798625720B4;
    }

    /**
     * @dev Check protocol operation mode. In whitelist mode, only members from whitelist and who have Minterest NFT
      can work with protocol.
     */
    modifier whitelistMode(address account) {
        require(address(whitelist) == address(0) || whitelist.isWhitelisted(account), ErrorCodes.WHITELISTED_ONLY);
        _;
    }
}
