pragma solidity ^0.5.16;

import "./CToken.sol";
import "./ErrorReporter.sol";
import "./PriceOracle.sol";
import "./ComptrollerInterface.sol";
import "./ComptrollerStorage.sol";

contract Comptroller is ComptrollerStorage, ComptrollerInterface, ComptrollerErrorReporter, ExponentialNoError {
    event MarketListed(CToken cToken);
    event MarketEntered(CToken cToken, address account);
    event MarketExited(CToken cToken, address account);
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);
    event NewCollateralFactor(CToken cToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);
    event ActionPaused(string action, bool pauseState);
    event ActionPaused(CToken cToken, string action, bool pauseState);
    event NewBorrowCap(CToken indexed cToken, uint newBorrowCap);
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    uint internal constant closeFactorMinMantissa = 0.05e18; 
    uint internal constant closeFactorMaxMantissa = 0.9e18; 
    uint internal constant collateralFactorMaxMantissa = 0.9e18; 

    constructor() public {
        admin = msg.sender;
    }

    function getAssetsIn(address account) external view returns (CToken[] memory) {
        CToken[] memory assetsIn = accountAssets[account];
        return assetsIn;
    }

    function checkMembership(address account, CToken cToken) external view returns (bool) {
        return markets[address(cToken)].accountMembership[account];
    }

    function enterMarkets(address[] memory cTokens) public returns (uint[] memory) {
        uint len = cTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            CToken cToken = CToken(cTokens[i]);
            results[i] = uint(addToMarketInternal(cToken, msg.sender));
        }

        return results;
    }

    function addToMarketInternal(CToken cToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(cToken)];

        require(marketToJoin.isListed, "MARKET_NOT_LISTED"); 

        if (marketToJoin.accountMembership[borrower] == true) {
            return Error.NO_ERROR;
        }

        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(cToken);

        emit MarketEntered(cToken, borrower);

        return Error.NO_ERROR;
    }

    function exitMarket(address cTokenAddress) external returns (uint) {
        CToken cToken = CToken(cTokenAddress);
        (uint oErr, uint tokensHeld, uint amountOwed, ) = cToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "GET_ACCOUNT_SNAPSHOT_FAILED"); 
        require(amountOwed == 0, "EXIT_MARKET_BALANCE_OWED"); 

        uint allowed = redeemAllowedInternal(cTokenAddress, msg.sender, tokensHeld);
        require(allowed == 0, "EXIT_MARKET_REJECTION"); 

        Market storage marketToExit = markets[address(cToken)];

        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        delete marketToExit.accountMembership[msg.sender];

        CToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == cToken) {
                assetIndex = i;
                break;
            }
        }

        assert(assetIndex < len);

        CToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        emit MarketExited(cToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint) {
        require(!mintGuardianPaused[cToken], "MINT_IS_PAUSED");
        require(markets[cToken].isListed, "MARKET_NOT_LISTED"); 

        return uint(Error.NO_ERROR);
    }

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint) {
        uint allowed = redeemAllowedInternal(cToken, redeemer, redeemTokens);
        require(allowed == uint(Error.NO_ERROR), "REDDEM_NOT_ALLOWED");

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address cToken, address redeemer, uint redeemTokens) internal returns (uint) {
        require(markets[cToken].isListed, "MARKET_NOT_LISTED"); 

        if (!markets[cToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, CToken(cToken), redeemTokens, 0);
        require(err == Error.NO_ERROR, "GET_HYPOTHETICAL_ACCOUNT_LIQUDITY_FAIL"); 
        require(shortfall <= 0, "INSUFFICIENT_LIQUIDITY"); 

        return uint(Error.NO_ERROR);
    }

    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external {
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("REDEEM_TOKENS_ZERO");
        }
    }

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint) {
        require(!borrowSeizeGuardianPaused, "ALL_BORROW_IS_PAUSED");
        require(!borrowGuardianPaused[cToken], "BORROW_IS_PAUSED");
        require(markets[cToken].isListed, "MARKET_NOT_LISTED"); 

        if (!markets[cToken].accountMembership[borrower]) {
            require(msg.sender == cToken, "SENDER_MUST_BE_CTOKEN");
            Error err = addToMarketInternal(CToken(msg.sender), borrower);
            require(err == Error.NO_ERROR, "ADD_TO_MARKET_FAIL");
            assert(markets[cToken].accountMembership[borrower]);
        }

        require(oracle.getUnderlyingPrice(CToken(cToken)) != 0, "PRICE_ERROR");

        uint borrowCap = borrowCaps[cToken];
        if (borrowCap != 0) {
            uint totalBorrows = CToken(cToken).totalBorrows();
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "MARKET_BORROW_CAP_REACHED");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, CToken(cToken), 0, borrowAmount);
        require(err == Error.NO_ERROR, "GET_HYPOTHETICAL_ACCOUNT_LIQUDITY_FAIL"); 
        require(shortfall <= 0, "INSUFFICIENT_LIQUIDITY"); 

        return uint(Error.NO_ERROR);
    }

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint) {

        require(markets[cToken].isListed, "MARKET_NOT_LISTED"); 
        return uint(Error.NO_ERROR);
    }

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint) {

        require(markets[cTokenBorrowed].isListed && markets[cTokenCollateral].isListed , "MARKET_NOT_LISTED"); 

        (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
        require(err == Error.NO_ERROR, "GET_ACCOUNT_LIQUDITY_FAIL"); 
        require(shortfall != 0, "INSUFFICIENT_SHORTFALL"); 

        uint borrowBalance = CToken(cTokenBorrowed).borrowBalanceStored(borrower);
        uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        require(repayAmount <= maxClose, "TOO_MUCH_REPAY"); 

        return uint(Error.NO_ERROR);
    }

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint) {
        require(!borrowSeizeGuardianPaused, "ALL_SEIZE_IS_PAUSED");
        require(!seizeGuardianPaused, "SEIZE_IS_PAUSED");

        seizeTokens;

        require(markets[cTokenCollateral].isListed && markets[cTokenBorrowed].isListed, "MARKET_NOT_LISTED"); 
        require(CToken(cTokenCollateral).comptroller() == CToken(cTokenBorrowed).comptroller(), "COMPTROLLER_MISMATCH"); 

        return uint(Error.NO_ERROR);
    }

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint) {
        require(!transferGuardianPaused, "TRANSFER_IS_PAUSED");

        uint allowed = redeemAllowedInternal(cToken, src, transferTokens);
        require(allowed == uint(Error.NO_ERROR), "REDEEM_ALLOWED_FAIL");

        return uint(Error.NO_ERROR);
    }

    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint cTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, CToken(0), 0, 0);
        return (uint(err), liquidity, shortfall);
    }

    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, CToken(0), 0, 0);
    }

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, CToken(cTokenModify), redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    function getHypotheticalAccountLiquidityInternal(
        address account,
        CToken cTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; 
        uint oErr;

        CToken[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            CToken asset = assets[i];

            (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) { 
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }

            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }

            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.cTokenBalance, vars.sumCollateral);
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            if (asset == cTokenModify) {
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint actualRepayAmount) external view returns (uint, uint) {
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(CToken(cTokenBorrowed));
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(CToken(cTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        uint exchangeRateMantissa = CToken(cTokenCollateral).exchangeRateStored(); 
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    function _setPriceOracle(PriceOracle newOracle) public returns (uint) {
    	require(msg.sender == admin, "ONLY_ADMIN");
        
        PriceOracle oldOracle = oracle;
        oracle = newOracle;

        emit NewPriceOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
    	require(msg.sender == admin, "ONLY_ADMIN");

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    function _setCollateralFactor(CToken cToken, uint newCollateralFactorMantissa) external returns (uint) {
    	require(msg.sender == admin, "ONLY_ADMIN");

        Market storage market = markets[address(cToken)];
        require(market.isListed, "MARKET_NOT_LISTED"); 

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        require(!lessThanExp(highLimit, newCollateralFactorExp), "INVALID_COLLATERAL_FACTOR"); 
        require(newCollateralFactorMantissa == 0 || oracle.getUnderlyingPrice(cToken) != 0, "PRICE_ERROR"); 

        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        emit NewCollateralFactor(cToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
    	require(msg.sender == admin, "ONLY_ADMIN");

        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

    function _supportMarket(CToken cToken) external returns (uint) {
    	require(msg.sender == admin, "ONLY_ADMIN");
    	require(!markets[address(cToken)].isListed, "MARKET_ALREADY_LISTED");

        cToken.isCToken(); 
        markets[address(cToken)] = Market({isListed: true, collateralFactorMantissa: 0});
        _addMarketInternal(address(cToken));

        emit MarketListed(cToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address cToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != CToken(cToken), "MARKET_ALREADY_ADDED");
        }
        allMarkets.push(CToken(cToken));
    }

    function _setMarketBorrowCaps(CToken[] calldata cTokens, uint[] calldata newBorrowCaps) external {
    	require(msg.sender == admin || msg.sender == borrowCapGuardian, "ONLY_ADMIN_OR_BORROWCAP_GUARDIAN"); 

        uint numMarkets = cTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "INVALID_INPUT");

        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(cTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(cTokens[i], newBorrowCaps[i]);
        }
    }

    function _setBorrowCapGuardian(address newBorrowCapGuardian) external {
        require(msg.sender == admin, "ONLY_ADMIN");

        address oldBorrowCapGuardian = borrowCapGuardian;
        borrowCapGuardian = newBorrowCapGuardian;

        emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
    }

    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        require(msg.sender == admin, "ONLY_ADMIN");

        address oldPauseGuardian = pauseGuardian;
        pauseGuardian = newPauseGuardian;

        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    function _setMintPaused(CToken cToken, bool state) public returns (bool) {
        require(markets[address(cToken)].isListed, "MARKET_ISNOT_LISTED");
        require(msg.sender == pauseGuardian || msg.sender == admin, "ONLY_ADMIN_OR_PAUSE_GUARDIAN");
        require(msg.sender == admin || state == true, "ONLY_ADMIN_AND_STATE_TRUE");

        mintGuardianPaused[address(cToken)] = state;
        emit ActionPaused(cToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(CToken cToken, bool state) public returns (bool) {
        require(markets[address(cToken)].isListed, "MARKET_ISNOT_LISTED");
        require(msg.sender == pauseGuardian || msg.sender == admin, "ONLY_ADMIN_OR_PAUSE_GUARDIAN");
        require(msg.sender == admin || state == true, "ONLY_ADMIN_AND_STATE_TRUE");

        borrowGuardianPaused[address(cToken)] = state;
        emit ActionPaused(cToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "ONLY_ADMIN_OR_PAUSE_GUARDIAN");
        require(msg.sender == admin || state == true, "ONLY_ADMIN_AND_STATE_TRUE");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "ONLY_ADMIN_OR_PAUSE_GUARDIAN");
        require(msg.sender == admin || state == true, "ONLY_ADMIN_AND_STATE_TRUE");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _setBorrowSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "ONLY_ADMIN_OR_PAUSE_GUARDIAN");
        require(msg.sender == admin || state == true, "ONLY_ADMIN_AND_STATE_TRUE");

        borrowSeizeGuardianPaused = state;
        emit ActionPaused("BorrowSeize", state);
        return state;
    }

    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == comptrollerImplementation;
    }

    function getAllMarkets() public view returns (CToken[] memory) {
        return allMarkets;
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }
}
