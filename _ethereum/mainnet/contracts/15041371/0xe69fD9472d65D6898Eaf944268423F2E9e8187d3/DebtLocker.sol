// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { Liquidator }            from "../modules/liquidations/contracts/Liquidator.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import "./MapleProxiedInternals.sol";

import { IDebtLocker }                                                                from "./interfaces/IDebtLocker.sol";
import "./Interfaces.sol";

import "./DebtLockerStorage.sol";

/// @title DebtLocker interacts with Loans on behalf of PoolV1.
contract DebtLocker is IDebtLocker, DebtLockerStorage, MapleProxiedInternals {

    /*****************/
    /*** Modifiers ***/
    /*****************/

    modifier whenProtocolNotPaused() {
        require(!IMapleGlobalsLike(_getGlobals()).protocolPaused(), "DL:PROTOCOL_PAUSED");
        _;
    }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == _factory(),        "DL:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "DL:M:FAILED");
    }

    function setImplementation(address newImplementation_) external override {
        require(msg.sender == _factory(),               "DL:SI:NOT_FACTORY");
        require(_setImplementation(newImplementation_), "DL:SI:FAILED");
    }

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external override {
        require(msg.sender == _getPoolDelegate(), "DL:U:NOT_POOL_DELEGATE");

        emit Upgraded(toVersion_, arguments_);

        IMapleProxyFactory(_factory()).upgradeInstance(toVersion_, arguments_);
    }

    /*******************************/
    /*** Pool Delegate Functions ***/
    /*******************************/

    function acceptNewTerms(address refinancer_, bytes[] calldata calls_, uint256 amount_) external override whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(), "DL:ANT:NOT_PD");

        address loanAddress = _loan;

        require(
            (IMapleLoanLike(loanAddress).claimableFunds() + _fundsToCapture == uint256(0)) &&
            (IMapleLoanLike(loanAddress).principal() == _principalRemainingAtLastClaim),
            "DL:ANT:NEED_TO_CLAIM"
        );

        require(
            amount_ == uint256(0) || ERC20Helper.transfer(IMapleLoanLike(loanAddress).fundsAsset(), loanAddress, amount_),
            "DL:ANT:TRANSFER_FAILED"
        );

        IMapleLoanLike(loanAddress).acceptNewTerms(refinancer_, calls_, uint256(0));

        // NOTE: This must be set after accepting the new terms, which affects the loan principal.
        _principalRemainingAtLastClaim = IMapleLoanLike(loanAddress).principal();
    }

    function claim() external override whenProtocolNotPaused returns (uint256[7] memory details_) {
        require(msg.sender == _pool, "DL:C:NOT_POOL");

        return _repossessed ? _handleClaimOfRepossessed(msg.sender, _loan) : _handleClaim(msg.sender, _loan);
    }

    function pullFundsFromLiquidator(address liquidator_, address token_, address destination_, uint256 amount_) external override {
        require(msg.sender == _getPoolDelegate(), "DL:SA:NOT_PD");

        Liquidator(liquidator_).pullFunds(token_, destination_, amount_);
    }

    function setAllowedSlippage(uint256 allowedSlippage_) external override whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(),    "DL:SAS:NOT_PD");
        require(allowedSlippage_ <= uint256(10_000), "DL:SAS:INVALID_SLIPPAGE");

        emit AllowedSlippageSet(_allowedSlippage = allowedSlippage_);
    }

    function setAuctioneer(address auctioneer_) external override whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(), "DL:SA:NOT_PD");

        emit AuctioneerSet(auctioneer_);

        Liquidator(_liquidator).setAuctioneer(auctioneer_);
    }

    function setFundsToCapture(uint256 amount_) override external whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(), "DL:SFTC:NOT_PD");

        emit FundsToCaptureSet(_fundsToCapture = amount_);
    }

    function setMinRatio(uint256 minRatio_) external override whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(), "DL:SMR:NOT_PD");

        emit MinRatioSet(_minRatio = minRatio_);
    }

    // Pool delegate can prematurely stop liquidation when there's still significant amount to be liquidated.
    function stopLiquidation() external override {
        require(msg.sender == _getPoolDelegate(), "DL:SL:NOT_PD");

        _liquidator = address(0);

        emit LiquidationStopped();
    }

    function triggerDefault() external override whenProtocolNotPaused {
        require(msg.sender == _pool, "DL:TD:NOT_POOL");

        address loanAddress = _loan;

        require(
            (IMapleLoanLike(loanAddress).claimableFunds() == uint256(0)) &&
            (IMapleLoanLike(loanAddress).principal() == _principalRemainingAtLastClaim),
            "DL:TD:NEED_TO_CLAIM"
        );

        _repossessed = true;

        // Ensure that principal is always up to date, claim function will clear out all payments, but on refinance we need to ensure that
        // accounting is updated properly when principal is updated and there are no claimable funds.

        // Repossess collateral and funds from Loan.
        ( uint256 collateralAssetAmount, ) = IMapleLoanLike(loanAddress).repossess(address(this));

        address collateralAsset = IMapleLoanLike(loanAddress).collateralAsset();
        address fundsAsset      = IMapleLoanLike(loanAddress).fundsAsset();

        if (collateralAsset == fundsAsset || collateralAssetAmount == uint256(0)) return;

        // Deploy Liquidator contract and transfer collateral.
        require(
            ERC20Helper.transfer(
                collateralAsset,
                _liquidator = address(new Liquidator(address(this), collateralAsset, fundsAsset, address(this), address(this), _getGlobals())),
                collateralAssetAmount
            ),
            "DL:TD:TRANSFER"
       );
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _handleClaim(address pool_, address loan_) internal returns (uint256[7] memory details_) {
        // Get loan state variables needed
        uint256 claimableFunds = IMapleLoanLike(loan_).claimableFunds();

        require(claimableFunds > uint256(0), "DL:HC:NOTHING_TO_CLAIM");

        // Send funds to pool
        IMapleLoanLike(loan_).claimFunds(claimableFunds, pool_);

        uint256 currentPrincipalRemaining = IMapleLoanLike(loan_).principal();

        // Determine how much of `claimableFunds` is principal
        uint256 principalPortion = _principalRemainingAtLastClaim - currentPrincipalRemaining;

        // Update state variables
        _principalRemainingAtLastClaim = currentPrincipalRemaining;

        // Set return values
        // Note: All fees get deducted and transferred during `loan.fundLoan()` that omits the need to
        // return the fees distribution to the pool.
        details_[0] = claimableFunds;
        details_[1] = claimableFunds - principalPortion;
        details_[2] = principalPortion;

        uint256 amountOfFundsToCapture = _fundsToCapture;

        if (amountOfFundsToCapture > uint256(0)) {
            details_[0] += amountOfFundsToCapture;
            details_[2] += amountOfFundsToCapture;

            _fundsToCapture = uint256(0);

            require(ERC20Helper.transfer(IMapleLoanLike(loan_).fundsAsset(), pool_, amountOfFundsToCapture), "DL:HC:CAPTURE_FAILED");
        }
    }

    function _handleClaimOfRepossessed(address pool_, address loan_) internal returns (uint256[7] memory details_) {
        require(!_isLiquidationActive(), "DL:HCOR:LIQ_NOT_FINISHED");

        address fundsAsset       = IMapleLoanLike(loan_).fundsAsset();
        uint256 principalToCover = _principalRemainingAtLastClaim;      // Principal remaining at time of liquidation
        uint256 fundsCaptured    = _fundsToCapture;

        // Funds recovered from liquidation and any unclaimed previous payment amounts
        uint256 recoveredFunds = IERC20Like(fundsAsset).balanceOf(address(this)) - fundsCaptured;

        uint256 totalClaimed = recoveredFunds + fundsCaptured;

        // If `recoveredFunds` is greater than `principalToCover`, the remaining amount is treated as interest in the context of the pool.
        // If `recoveredFunds` is less than `principalToCover`, the difference is registered as a shortfall.
        details_[0] = totalClaimed;
        details_[1] = recoveredFunds > principalToCover ? recoveredFunds - principalToCover : uint256(0);
        details_[2] = fundsCaptured;
        details_[5] = recoveredFunds > principalToCover ? principalToCover : recoveredFunds;
        details_[6] = principalToCover > recoveredFunds ? principalToCover - recoveredFunds : uint256(0);

        _fundsToCapture = uint256(0);
        _repossessed    = false;

        require(ERC20Helper.transfer(fundsAsset, pool_, totalClaimed), "DL:HCOR:TRANSFER");
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function allowedSlippage() external view override returns (uint256 allowedSlippage_) {
        return _allowedSlippage;
    }

    function amountRecovered() external view override returns (uint256 amountRecovered_) {
        return _amountRecovered;
    }

    function factory() external view override returns (address factory_) {
        return _factory();
    }

    function fundsToCapture() external view override returns (uint256 fundsToCapture_) {
        return _fundsToCapture;
    }

    function getExpectedAmount(uint256 swapAmount_) external view override whenProtocolNotPaused returns (uint256 returnAmount_) {
        address loanAddress     = _loan;
        address collateralAsset = IMapleLoanLike(loanAddress).collateralAsset();
        address fundsAsset      = IMapleLoanLike(loanAddress).fundsAsset();
        address globals         = _getGlobals();

        uint8 collateralAssetDecimals = IERC20Like(collateralAsset).decimals();

        uint256 oracleAmount =
            swapAmount_
                * IMapleGlobalsLike(globals).getLatestPrice(collateralAsset)  // Convert from `fromAsset` value.
                * uint256(10) ** uint256(IERC20Like(fundsAsset).decimals())   // Convert to `toAsset` decimal precision.
                * (uint256(10_000) - _allowedSlippage)                        // Multiply by allowed slippage basis points
                / IMapleGlobalsLike(globals).getLatestPrice(fundsAsset)       // Convert to `toAsset` value.
                / uint256(10) ** uint256(collateralAssetDecimals)             // Convert from `fromAsset` decimal precision.
                / uint256(10_000);                                            // Divide basis points for slippage.

        uint256 minRatioAmount = (swapAmount_ * _minRatio) / (uint256(10) ** collateralAssetDecimals);

        return oracleAmount > minRatioAmount ? oracleAmount : minRatioAmount;
    }

    function implementation() external view override returns (address implementation_) {
        return _implementation();
    }

    function liquidator() external view override returns (address liquidator_) {
        return _liquidator;
    }

    function loan() external view override returns (address loan_) {
        return _loan;
    }

    function minRatio() external view override returns (uint256 minRatio_) {
        return _minRatio;
    }

    function pool() external view override returns (address pool_) {
        return _pool;
    }

    function poolDelegate() external override view returns (address poolDelegate_) {
        return _getPoolDelegate();
    }

    function principalRemainingAtLastClaim() external view override returns (uint256 principalRemainingAtLastClaim_) {
        return _principalRemainingAtLastClaim;
    }

    function repossessed() external view override returns (bool repossessed_) {
        return _repossessed;
    }

    /*******************************/
    /*** Internal View Functions ***/
    /*******************************/

    function _getGlobals() internal view returns (address globals_) {
        return IPoolFactoryLike(IPoolLike(_pool).superFactory()).globals();
    }

    function _getPoolDelegate() internal view returns(address poolDelegate_) {
        return IPoolLike(_pool).poolDelegate();
    }

    function _isLiquidationActive() internal view returns (bool isActive_) {
        address liquidatorAddress = _liquidator;

        return (liquidatorAddress != address(0)) && (IERC20Like(IMapleLoanLike(_loan).collateralAsset()).balanceOf(liquidatorAddress) != uint256(0));
    }

}
