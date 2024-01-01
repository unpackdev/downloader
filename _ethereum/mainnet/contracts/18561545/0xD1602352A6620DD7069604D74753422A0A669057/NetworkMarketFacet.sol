// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./LibAppStorage.sol";
import "./LibMarketStorage.sol";
import "./IMarketRegistry.sol";
import "./LibNetworkMarket.sol";
import "./IPriceConsumer.sol";
import "./LibMarketProvider.sol";
import "./LibMeta.sol";
import "./IProtocolRegistry.sol";
import "./IAggregationExecutor.sol";
import "./IAggregationRouterV5.sol";

contract NetworkMarketFacet is Modifiers {
    using SafeERC20 for IERC20;

    /**
    /// @dev function to create Single || Multi (ERC20) Loan Offer by the BORROWER
    /// @param loanDetails {see: LibMarketStorage}

    */
    function createLoanEth(
        LibMarketStorage.LoanDetailsNetworkData memory loanDetails
    ) external payable whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            IProtocolRegistry(address(this)).isStableApproved(
                loanDetails.borrowStableCoin
            ),
            "GTM: not approved stable coin"
        );

        uint256 newLoanId = ms.loanIdNetwork + 1;
        uint256 stableCoinDecimals = IERC20Metadata(
            loanDetails.borrowStableCoin
        ).decimals();
        require(
            loanDetails.loanAmountInBorrowed >=
                (IMarketRegistry(address(this)).getMinLoanAmountAllowed() *
                    (10 ** stableCoinDecimals)),
            "GLM: min loan amount invalid"
        );

        require(
            msg.value == loanDetails.collateralAmount,
            "GNM: Loan Amount Invalid"
        );

        uint256 ltv = LibNetworkMarket.calculateLTV(
            loanDetails.collateralAmount,
            loanDetails.borrowStableCoin,
            loanDetails.loanAmountInBorrowed
        );
        uint256 maxLtv = LibNetworkMarket.getMaxLoanAmount(
            IPriceConsumer(address(this)).getCollateralPriceinStable(
                IPriceConsumer(address(this)).wethAddress(),
                loanDetails.borrowStableCoin,
                loanDetails.collateralAmount
            ),
            LibMeta._msgSender()
        );

        require(
            loanDetails.loanAmountInBorrowed <= maxLtv,
            "GNM: LTV not allowed."
        );
        require(
            ltv > IMarketRegistry(address(this)).getLTVPercentage(),
            "GNM: Can not create loan at liquidation level."
        );

        ms.borrowerLoanIdsNetwork[LibMeta._msgSender()].push(newLoanId);
        ms.borrowerLoanNetwork[newLoanId] = LibMarketStorage.LoanDetailsNetwork(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.isInsured,
            loanDetails.collateralAmount,
            loanDetails.borrowStableCoin,
            LibMarketStorage.LoanStatus.INACTIVE,
            payable(LibMeta._msgSender()),
            0,
            0,
            IMarketRegistry(address(this)).getLTVPercentage()
        );

        emit LibNetworkMarket.LoanOfferCreated(
            newLoanId,
            ms.borrowerLoanNetwork[newLoanId]
        );
        ms.loanIdNetwork++;
    }

    /**
    @dev function to adjust already created loan offer, while in inactive state
    @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    @param _newTermsLengthInDays, borrower changing the loan term in days
    @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    @param _isInsured, isinsured true or false
     */
    function updateEthLoan(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint256 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isInsured
    ) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsNetwork storage borrowerLoanNetwork = ms
            .borrowerLoanNetwork[_loanIdAdjusted];

        require(
            borrowerLoanNetwork.loanStatus ==
                LibMarketStorage.LoanStatus.INACTIVE,
            "loan status has to be inactive"
        );
        require(
            borrowerLoanNetwork.borrower == LibMeta._msgSender(),
            "GNM, Only Borrow Adjust Loan"
        );
        uint256 stableCoinDecimals = IERC20Metadata(
            borrowerLoanNetwork.borrowStableCoin
        ).decimals();

        require(
            _newLoanAmountBorrowed >=
                (IMarketRegistry(address(this)).getMinLoanAmountAllowed() *
                    (10 ** stableCoinDecimals)),
            "GNM: min loan amount invalid"
        );

        uint256 maxLtv = LibNetworkMarket.getMaxLoanAmount(
            IPriceConsumer(address(this)).getCollateralPriceinStable(
                IPriceConsumer(address(this)).wethAddress(),
                borrowerLoanNetwork.borrowStableCoin,
                borrowerLoanNetwork.collateralAmount
            ),
            LibMeta._msgSender()
        );

        require(maxLtv != 0, "GNM: not tier, cannot adjust loan");
        require(_newLoanAmountBorrowed <= maxLtv, "GNM: LTV not allowed.");

        ms.borrowerLoanNetwork[_loanIdAdjusted] = LibMarketStorage
            .LoanDetailsNetwork(
                _newLoanAmountBorrowed,
                _newTermsLengthInDays,
                _newAPYOffer,
                _isInsured,
                borrowerLoanNetwork.collateralAmount,
                borrowerLoanNetwork.borrowStableCoin,
                LibMarketStorage.LoanStatus.INACTIVE,
                payable(LibMeta._msgSender()),
                borrowerLoanNetwork.paybackAmount,
                block.timestamp + 20 seconds,
                borrowerLoanNetwork.ltvpercentage
            );

        emit LibNetworkMarket.LoanOfferAdjusted(
            _loanIdAdjusted,
            borrowerLoanNetwork
        );
    }

    /**
    @dev function to cancel the created laon offer for  type Single || Multi  Colletrals
    @param _loanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function ethLoanOfferCancel(uint256 _loanId) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            ms.borrowerLoanNetwork[_loanId].loanStatus ==
                LibMarketStorage.LoanStatus.INACTIVE,
            "GNM, Loan cannot be cancel"
        );
        require(
            ms.borrowerLoanNetwork[_loanId].borrower == LibMeta._msgSender(),
            "GNM, Only Borrow can cancel"
        );

        ms.borrowerLoanNetwork[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .CANCELLED;

        (bool success, ) = payable(LibMeta._msgSender()).call{
            value: ms.borrowerLoanNetwork[_loanId].collateralAmount
        }("");
        require(success, "GNM: ETH transfer failed");

        emit LibNetworkMarket.LoanOfferCancel(
            _loanId,
            LibMeta._msgSender(),
            ms.borrowerLoanNetwork[_loanId].loanStatus
        );
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param _loanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateLoanEth(
        uint256 _loanId,
        uint256 _stableCoinAmount,
        bool _autoSell
    ) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            block.timestamp > ms.borrowerLoanNetwork[_loanId].unlockTime,
            "Loan is timed locked"
        );
        require(
            ms.borrowerLoanNetwork[_loanId].borrower != LibMeta._msgSender(),
            "GNM, self activation not allowed"
        );
        require(
            ms.borrowerLoanNetwork[_loanId].loanStatus ==
                LibMarketStorage.LoanStatus.INACTIVE,
            "GNM, not inactive"
        );

        uint256 platformFee = (ms
            .borrowerLoanNetwork[_loanId]
            .loanAmountInBorrowed *
            (IProtocolRegistry(address(this)).getGovPlatformFee())) / (10000);

        ms.borrowerLoanNetwork[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .ACTIVE;

        /// @dev adding platform fee for the  Network Loan Contract in stableCoinWithdrawable,
        /// which can be withdrawable by the superadmin from the Network Loan Contract
        ms.stableCoinWithdrawable[
            ms.borrowerLoanNetwork[_loanId].borrowStableCoin
        ] += platformFee;

        /// @dev save the activated loan id to the lender details mapping
        ms.activatedLoanNetwork[_loanId] = LibMarketStorage.LenderDetails({
            lender: payable(LibMeta._msgSender()),
            activationLoanTimeStamp: block.timestamp,
            autoSell: _autoSell
        });

        //push active loan ids to the lendersactivatedloanIds mapping
        ms.activatedLoanIdsNetwork[LibMeta._msgSender()].push(_loanId);

        if (
            !IMarketRegistry(address(this)).isWhitelistedForActivation(
                LibMeta._msgSender()
            )
        ) {
            require(
                ms.loanActivatedLimit[LibMeta._msgSender()] + 1 <=
                    IMarketRegistry(address(this)).getLoanActivateLimit(),
                "GTM: you cannot lend more loans"
            );
            ms.loanActivatedLimit[LibMeta._msgSender()]++;
        }

        uint256 calulatedLTV = LibNetworkMarket.getLtv(ms, _loanId);

        require(
            calulatedLTV > ms.borrowerLoanNetwork[_loanId].ltvpercentage,
            "Can not activate loan at liquidation level"
        );

        uint256 maxLoanAmount = LibNetworkMarket.getMaxLoanAmount(
            IPriceConsumer(address(this)).getCollateralPriceinStable(
                IPriceConsumer(address(this)).wethAddress(),
                ms.borrowerLoanNetwork[_loanId].borrowStableCoin,
                ms.borrowerLoanNetwork[_loanId].collateralAmount
            ),
            ms.borrowerLoanNetwork[_loanId].borrower
        );

        require(maxLoanAmount != 0, "GNM: borrower not eligible, no tierLevel");

        if (
            maxLoanAmount < ms.borrowerLoanNetwork[_loanId].loanAmountInBorrowed
        ) {
            // maxLoanAmount is now assigning in the loan Details struct
            require(
                _stableCoinAmount <= maxLoanAmount &&
                    _stableCoinAmount >
                    maxLoanAmount - ((maxLoanAmount * 3) / 100),
                "GNM: loan amount not equal maxLoanAmount"
            );
            ms
                .borrowerLoanNetwork[_loanId]
                .loanAmountInBorrowed = _stableCoinAmount;
        }

        uint256 apyFee = LibMarketProvider.getAPYFee(
            ms.borrowerLoanNetwork[_loanId].loanAmountInBorrowed,
            ms.borrowerLoanNetwork[_loanId].apyOffer,
            ms.borrowerLoanNetwork[_loanId].termsLengthInDays
        );

        uint256 loanAmountAfterCut = ms
            .borrowerLoanNetwork[_loanId]
            .loanAmountInBorrowed - (apyFee + platformFee);

        /// @dev approving the loan amount from the front end
        /// @dev keep the APYFEE  in the contract  before  transfering the stable coins to borrower.
        IERC20(ms.borrowerLoanNetwork[_loanId].borrowStableCoin)
            .safeTransferFrom(
                LibMeta._msgSender(),
                address(this),
                ms.borrowerLoanNetwork[_loanId].loanAmountInBorrowed
            );

        /// @dev loan amount sending to borrower
        IERC20(ms.borrowerLoanNetwork[_loanId].borrowStableCoin).safeTransfer(
            ms.borrowerLoanNetwork[_loanId].borrower,
            loanAmountAfterCut
        );

        emit LibNetworkMarket.LoanOfferActivated(
            _loanId,
            LibMeta._msgSender(),
            loanAmountAfterCut,
            _autoSell
        );
    }

    function _collateralSwap(
        LibMarketStorage.LoanDetailsNetwork memory loanDetails,
        SwapInfo calldata swapInfo
    ) internal {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            address(swapInfo.desc.srcToken) == ms.networkTokenAddress,
            "not collateral token"
        );
        require(
            address(swapInfo.desc.dstToken) == loanDetails.borrowStableCoin,
            "not stable token"
        );
        require(
            swapInfo.desc.dstReceiver == address(this),
            "receiver not contract itself"
        );
        require(
            swapInfo.desc.amount == loanDetails.collateralAmount,
            "collateral amount not equal to swap amount"
        );

        (uint256 returnAmount, uint256 spentAmount) = IAggregationRouterV5(
            ms.aggregationRouterV5
        ).swap{value: loanDetails.collateralAmount}(
            swapInfo.executor,
            swapInfo.desc,
            swapInfo.permit,
            swapInfo.data
        );

        emit LibNetworkMarket.SwapEth(
            address(this),
            swapInfo.desc.amount,
            spentAmount,
            returnAmount
        );
    }

    function _liquidateAutoSellOn(
        uint256 _loanId,
        SwapInfo calldata _swapInfo,
        uint256 _earnedAPY,
        uint256 _unEarned
    ) internal {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        LibMarketStorage.LoanDetailsNetwork memory loanDetails = ms
            .borrowerLoanNetwork[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanNetwork[_loanId];

        ms.borrowerLoanNetwork[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .LIQUIDATED;

        uint256 previousBalance = IERC20(loanDetails.borrowStableCoin)
            .balanceOf(address(this));

        _collateralSwap(loanDetails, _swapInfo);

        uint256 newBalance = IERC20(loanDetails.borrowStableCoin).balanceOf(
            address(this)
        );
        uint256 totalSwapped = newBalance - previousBalance;
        require(
            totalSwapped >= loanDetails.loanAmountInBorrowed,
            "swap amount is not enough to cover the lender loan"
        );

        uint256 autosellFeeinStable = LibMarketProvider.getAPYFee(
            loanDetails.loanAmountInBorrowed,
            IProtocolRegistry(address(this)).getAutosellPercentage(),
            loanDetails.termsLengthInDays
        );
        uint256 leftAmount = totalSwapped - loanDetails.loanAmountInBorrowed;

        ms.stableCoinWithdrawable[loanDetails.borrowStableCoin] +=
            autosellFeeinStable +
            leftAmount +
            _unEarned;

        IERC20(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            (loanDetails.loanAmountInBorrowed + _earnedAPY) -
                autosellFeeinStable
        );

        emit LibNetworkMarket.AutoLiquidatedEth(
            _loanId,
            LibMarketStorage.LoanStatus.LIQUIDATED
        );
    }

    function _liquidateAutsellOff(
        uint256 _loanId,
        uint256 _earnedAPYFee
    ) internal {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsNetwork memory loanDetails = ms
            .borrowerLoanNetwork[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanNetwork[_loanId];

        ms.borrowerLoanNetwork[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .LIQUIDATED;

        uint256 thresholdFeeinStable = (loanDetails.loanAmountInBorrowed *
            IProtocolRegistry(address(this)).getThresholdPercentage()) / 10000;

        //network loan market will the repay staked collateral  to the borrower
        uint256 collateralAmountinStable = IPriceConsumer(address(this))
            .getCollateralPriceinStable(
                IPriceConsumer(address(this)).wethAddress(),
                loanDetails.borrowStableCoin,
                loanDetails.collateralAmount
            );

        if (
            collateralAmountinStable <=
            loanDetails.loanAmountInBorrowed + thresholdFeeinStable
        ) {
            (bool success, ) = payable(lenderDetails.lender).call{
                value: loanDetails.collateralAmount
            }("");
            require(success, "GNM: ETH transfer failed");
        } else if (
            collateralAmountinStable >
            loanDetails.loanAmountInBorrowed + thresholdFeeinStable
        ) {
            uint256 exceedAltcoinValue = IPriceConsumer(address(this))
                .getStablePriceInCollateral(
                    loanDetails.borrowStableCoin,
                    IPriceConsumer(address(this)).wethAddress(),
                    collateralAmountinStable -
                        (loanDetails.loanAmountInBorrowed +
                            thresholdFeeinStable)
                );
            uint256 collateralToLender = loanDetails.collateralAmount -
                exceedAltcoinValue;
            ms.collateralsWithdrawableNetwork[
                address(this)
            ] += exceedAltcoinValue;

            (bool success, ) = payable(lenderDetails.lender).call{
                value: collateralToLender
            }("");
            require(success, "GNM: ETH transfer failed");
        }

        require(
            IERC20(loanDetails.borrowStableCoin).transfer(
                lenderDetails.lender,
                _earnedAPYFee
            ),
            "GNM: Lender Amount Transfer Failed"
        );

        (bool successPaybackEth, ) = payable(loanDetails.borrower).call{
            value: loanDetails.paybackAmount
        }("");
        require(successPaybackEth, "GNM: payback eth failed to borrower");

        emit LibNetworkMarket.LiquidatedCollaterals(
            _loanId,
            LibMarketStorage.LoanStatus.LIQUIDATED
        );
    }

    /**
    @dev payback loan full by the borrower to the lender

     */
    function fullLoanPaybackEthEarly(uint256 _loanId) internal {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanNetwork[_loanId];

        LibMarketStorage.LoanDetailsNetwork memory loanDetails = ms
            .borrowerLoanNetwork[_loanId];

        (
            uint256 finalPaybackAmounttoLender,
            uint256 earnedAPYFee
        ) = LibNetworkMarket.getTotalPaybackAmount(_loanId);

        uint256 apyFeeOriginal = LibMarketProvider.getAPYFee(
            loanDetails.loanAmountInBorrowed,
            loanDetails.apyOffer,
            loanDetails.termsLengthInDays
        );

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;
        // adding the unearned APY in the contract stableCoinWithdrawable mapping
        // only superAdmin can withdraw this much amount
        ms.stableCoinWithdrawable[
            ms.borrowerLoanNetwork[_loanId].borrowStableCoin
        ] += unEarnedAPYFee;

        uint256 paybackAmount = ms.borrowerLoanNetwork[_loanId].paybackAmount;
        ms
            .borrowerLoanNetwork[_loanId]
            .paybackAmount = finalPaybackAmounttoLender;
        ms.borrowerLoanNetwork[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .CLOSED;

        //we will first transfer the loan payback amount from borrower to the contract address.
        IERC20(ms.borrowerLoanNetwork[_loanId].borrowStableCoin)
            .safeTransferFrom(
                ms.borrowerLoanNetwork[_loanId].borrower,
                address(this),
                ms.borrowerLoanNetwork[_loanId].loanAmountInBorrowed -
                    paybackAmount
            );
        IERC20(ms.borrowerLoanNetwork[_loanId].borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            finalPaybackAmounttoLender
        );

        //contract will the repay staked collateral  to the borrower after receiving the loan payback amount
        (bool success, ) = payable(LibMeta._msgSender()).call{
            value: ms.borrowerLoanNetwork[_loanId].collateralAmount
        }("");
        require(success, "GNM: ETH transfer failed");

        emit LibNetworkMarket.FullLoanPaybacked(
            _loanId,
            LibMeta._msgSender(),
            LibMarketStorage.LoanStatus.CLOSED
        );
    }

    /**
    @dev  loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function paybackEth(uint256 _loanId, uint256 _paybackAmount) external {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsNetwork memory loanDetails = ms
            .borrowerLoanNetwork[_loanId];

        require(
            ms.borrowerLoanNetwork[_loanId].borrower ==
                payable(LibMeta._msgSender()),
            "GNM, not borrower"
        );
        require(
            ms.borrowerLoanNetwork[_loanId].loanStatus ==
                LibMarketStorage.LoanStatus.ACTIVE,
            "GNM, not active"
        );

        require(
            _paybackAmount > 0 &&
                _paybackAmount <=
                loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount,
            "GLM: Invalid Payback Loan Amount"
        );
        require(
            !LibNetworkMarket.isLiquidationPending(_loanId),
            "GNM: Loan Already Paid or Liquidated"
        );

        uint256 totalPayback = _paybackAmount + loanDetails.paybackAmount;
        if (totalPayback >= loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEthEarly(_loanId);
        } else {
            ms.borrowerLoanNetwork[_loanId].paybackAmount =
                ms.borrowerLoanNetwork[_loanId].paybackAmount +
                _paybackAmount;
            IERC20(loanDetails.borrowStableCoin).safeTransferFrom(
                payable(LibMeta._msgSender()),
                address(this),
                _paybackAmount
            );

            emit LibNetworkMarket.PartialLoanPaybacked(
                _loanId,
                _paybackAmount,
                payable(LibMeta._msgSender())
            );
        }
    }

    /**
    @dev liquidate call from the  world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
    */

    function liquidateLoanNetwork(
        uint256 _loanId,
        SwapInfo calldata swapInfo
    ) external onlyLiquidator(LibMeta._msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            ms.borrowerLoanNetwork[_loanId].loanStatus ==
                LibMarketStorage.LoanStatus.ACTIVE,
            "GNM, not active, not available loan id, payback or liquidated"
        );

        require(
            LibNetworkMarket.isLiquidationPending(_loanId),
            "GNM: Liquidation Error"
        );

        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanNetwork[_loanId];

        (, uint256 earnedAPYFee) = LibNetworkMarket.getTotalPaybackAmount(
            _loanId
        );

        uint256 apyFeeOriginal = LibMarketProvider.getAPYFee(
            ms.borrowerLoanNetwork[_loanId].loanAmountInBorrowed,
            ms.borrowerLoanNetwork[_loanId].apyOffer,
            ms.borrowerLoanNetwork[_loanId].termsLengthInDays
        );
        /// @dev as we get the payback amount according to the days passed...
        // let say if (days passed earned APY) is greater than the original APY,
        // then we only sent the earned apy fee amount to the lender
        if (earnedAPYFee > apyFeeOriginal) {
            earnedAPYFee = apyFeeOriginal;
        }

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;

        if (lenderDetails.autoSell) {
            _liquidateAutoSellOn(
                _loanId,
                swapInfo,
                earnedAPYFee,
                unEarnedAPYFee
            );
        } else {
            //send collateral  to the lender
            _liquidateAutsellOff(_loanId, earnedAPYFee);
        }
    }

    /**
    @dev get loan details of the single or multi-
     */
    function getBorrowerLoanNetwork(
        uint256 _loanId
    ) external view returns (LibMarketStorage.LoanDetailsNetwork memory) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        return ms.borrowerLoanNetwork[_loanId];
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetailsNetwork(
        uint256 _loanId
    ) external view returns (LibMarketStorage.LenderDetails memory) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        return ms.activatedLoanNetwork[_loanId];
    }

    /// @dev only super admin can withdraw coins
    function withdrawCoinFromNetwork(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        uint256 availableAmount = ms.collateralsWithdrawableNetwork[
            address(this)
        ];
        require(availableAmount > 0, "GNM: collateral not available");
        require(_withdrawAmount <= availableAmount, "GNL: Amount Invalid");
        ms.collateralsWithdrawableNetwork[address(this)] -= _withdrawAmount;
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GNM: ETH transfer failed");
        emit LibNetworkMarket.WithdrawNetworkCoin(
            _walletAddress,
            _withdrawAmount
        );
    }

    function getCollateralsWithdrawableNetwork()
        external
        view
        returns (uint256)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        return ms.collateralsWithdrawableNetwork[address(this)];
    }

    function getMaxLoanAmountNetwork(
        uint256 collateralInBorrowed,
        address borrower
    ) external view returns (uint256) {
        return
            LibNetworkMarket.getMaxLoanAmount(collateralInBorrowed, borrower);
    }

    function getLtvNetworkLoan(
        uint256 _networkLoanId
    ) external view returns (uint256) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        return LibNetworkMarket.getLtv(ms, _networkLoanId);
    }

    function isLiquidationPendingNetwork(
        uint256 _networkLoanId
    ) external view returns (bool) {
        return LibNetworkMarket.isLiquidationPending(_networkLoanId);
    }

    function getTotalPaybackAmountNetwork(
        uint256 _networkLoanId
    )
        external
        view
        returns (uint256 loanAmountwithEarnedAPYFee, uint256 earnedAPYFee)
    {
        return LibNetworkMarket.getTotalPaybackAmount(_networkLoanId);
    }

    function getUserLoanActivateLimit(
        address _wallet
    ) external view returns (uint256) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        return ms.loanActivatedLimit[_wallet];
    }
}
