// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibMarketStorage.sol";

import "./LibAppStorage.sol";
import "./IUserTier.sol";
import "./IPriceConsumer.sol";
import "./IMarketRegistry.sol";

library LibNetworkMarket {
    event LoanOfferCreated(
        uint256 _loanId,
        LibMarketStorage.LoanDetailsNetwork _loanDetails
    );

    event LoanOfferAdjusted(
        uint256 _loanId,
        LibMarketStorage.LoanDetailsNetwork _loanDetails
    );

    event LoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _stableCoinAmount,
        bool _autoSell
    );

    event LoanOfferCancel(
        uint256 loanId,
        address _borrower,
        LibMarketStorage.LoanStatus loanStatus
    );

    event FullLoanPaybacked(
        uint256 loanId,
        address _borrower,
        LibMarketStorage.LoanStatus loanStatus
    );

    event PartialLoanPaybacked(
        uint256 loanId,
        uint256 paybackAmount,
        address _borrower
    );

    event AutoLiquidatedEth(
        uint256 _loanId,
        LibMarketStorage.LoanStatus loanStatus
    );

    event LiquidatedCollaterals(
        uint256 _loanId,
        LibMarketStorage.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    event SwapEth(
        address sender,
        uint256 srcAmount,
        uint256 spendAmount,
        uint256 returnAmount
    );

    /// @dev function to get the max loan amount according to the borrower tier level
    /// @param collateralInBorrowed amount of collateral in stable coin DAI, USDT
    /// @param borrower address of the borrower who holds some tier level
    function getMaxLoanAmount(
        uint256 collateralInBorrowed,
        address borrower
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory tierData = IUserTier(address(this))
            .getTierDatabyGovBalance(borrower);
        return (collateralInBorrowed * tierData.loantoValue) / 100;
    }

    /**
    @dev returns the LTV percentage of the loan amount in borrowed of the staked colletral 
    @param _loanId loan ID for which ltv we are getting
     */
    function getLtv(
        LibMarketStorage.MarketStorage storage ms,
        uint256 _loanId
    ) internal view returns (uint256) {
        LibMarketStorage.LoanDetailsNetwork memory loanDetails = ms
            .borrowerLoanNetwork[_loanId];

        return
            calculateLTV(
                loanDetails.collateralAmount,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed - (loanDetails.paybackAmount)
            );
    }

    /**
    @dev Calculates LTV based on DEX price
    @param _stakedCollateralAmount amount of staked collateral of Network Coin
    @param _loanAmount total borrower loan amount in borrowed .
     */
    function calculateLTV(
        uint256 _stakedCollateralAmount,
        address _stableCoin,
        uint256 _loanAmount
    ) internal view returns (uint256) {
        uint256 priceofCollateral = IPriceConsumer(address(this))
            .getCollateralPriceinStable(
                IPriceConsumer(address(this)).wethAddress(),
                _stableCoin,
                _stakedCollateralAmount
            );
        return (priceofCollateral * 100) / _loanAmount;
    }

    /**
    @dev function to check the loan is pending for liqudation or not
    @param _loanId for which loan liquidation checking
     */
    function isLiquidationPending(
        uint256 _loanId
    ) internal view returns (bool) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanNetwork[_loanId];
        LibMarketStorage.LoanDetailsNetwork memory loanDetails = ms
            .borrowerLoanNetwork[_loanId];

        uint256 loanTermLengthPassedInDays = (block.timestamp -
            lenderDetails.activationLoanTimeStamp) / 86400;

        // @dev get the LTV percentage
        uint256 calulatedLTV = getLtv(ms, _loanId);
        /// @dev the collateral is less than liquidation threshold percentage/loan term length end ok for liquidation
        ///  @dev loanDetails.termsLengthInDays + 1 is which we are giving extra time to the borrower to payback the collateral
        if (
            calulatedLTV <= loanDetails.ltvpercentage ||
            loanTermLengthPassedInDays >= loanDetails.termsLengthInDays + 1
        ) return true;
        else return false;
    }

    /// @dev function getting the total payback amount and earned apy amount to the lender
    /// @param _loanId loanId of the activated loans
    function getTotalPaybackAmount(
        uint256 _loanId
    )
        internal
        view
        returns (uint256 loanAmountwithEarnedAPYFee, uint256 earnedAPYFee)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsNetwork memory loanDetails = ms
            .borrowerLoanNetwork[_loanId];

        uint256 loanTermLengthPassed = block.timestamp -
            (ms.activatedLoanNetwork[_loanId].activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400;

        earnedAPYFee = ((loanDetails.loanAmountInBorrowed *
            loanDetails.apyOffer *
            loanTermLengthPassedInDays) /
            10000 /
            365);

        return (loanDetails.loanAmountInBorrowed + earnedAPYFee, earnedAPYFee);
    }
}
