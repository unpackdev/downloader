// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./LibAppStorage.sol";
import "./LibMarketStorage.sol";
import "./IMarketRegistry.sol";

import "./LibTokenMarket.sol";
import "./IUserTier.sol";
import "./IClaimToken.sol";
import "./LibMarketProvider.sol";
import "./LibMeta.sol";
import "./IProtocolRegistry.sol";

contract TokenMarketFacet is Modifiers {
    using SafeERC20 for IERC20;

    /// @dev function to create Single || Multi Token(ERC20) Loan Offer by the BORROWER
    /// @param loanDetails loan details borrower is making for the loan
    function createLoanToken(
        LibMarketStorage.LoanDetailsTokenData memory loanDetails
    ) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            IProtocolRegistry(address(this)).isStableApproved(
                loanDetails.borrowStableCoin
            ),
            "GTM: not approved stable coin"
        );

        uint256 newLoanId = ms.loanIdToken + 1;
        uint256 collateralTokenLength = loanDetails
            .stakedCollateralTokens
            .length;
        require(
            collateralTokenLength <=
                IMarketRegistry(address(this)).getMultiCollateralLimit(),
            "GLM: Collateral Length Exceeded"
        );
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
            loanDetails.stakedCollateralTokens.length ==
                loanDetails.stakedCollateralAmounts.length &&
                loanDetails.stakedCollateralTokens.length ==
                loanDetails.isMintSp.length,
            "GLM: Tokens and amounts length must be same"
        );

        require(
            LibTokenMarket.checkApprovalCollaterals(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.isMintSp,
                LibMeta._msgSender()
            ),
            "Collateral Approval Error"
        );

        (, , uint256 collatetralInBorrowed) = LibTokenMarket.getltvCalculations(
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            loanDetails.loanAmountInBorrowed,
            LibMeta._msgSender(),
            loanDetails.tierType
        );

        uint256 response = IUserTier(address(this)).isCreateLoanTokenUnderTier(
            LibMeta._msgSender(),
            loanDetails.loanAmountInBorrowed,
            collatetralInBorrowed,
            loanDetails.stakedCollateralTokens,
            loanDetails.tierType
        );
        require(response == 200, "offer not under tier");

        ms.borrowerLoanIdsToken[LibMeta._msgSender()].push(newLoanId);
        //loop through all staked collateral tokens.
        ms.borrowerLoanToken[newLoanId] = LibMarketStorage.LoanDetailsToken(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            LibMarketStorage.LoanStatus.INACTIVE,
            LibMeta._msgSender(),
            0,
            loanDetails.isMintSp,
            loanDetails.tierType,
            0,
            IMarketRegistry(address(this)).getLTVPercentage()
        );

        emit LibTokenMarket.LoanOfferCreatedToken(
            newLoanId,
            ms.borrowerLoanToken[newLoanId]
        );
        ms.loanIdToken++;
    }

    /// @dev function to adjust already created loan offer, while in inactive state
    /// @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    /// @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    /// @param _newTermsLengthInDays, borrower changing the loan term in days
    /// @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    /// @param _isInsured, isinsured true or false

    function updateTokenLoan(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint256 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isInsured
    ) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanIdAdjusted];

        require(
            loanDetails.loanStatus == LibMarketStorage.LoanStatus.INACTIVE,
            "loan status has to be inactive"
        );
        uint256 stableCoinDecimals = IERC20Metadata(
            loanDetails.borrowStableCoin
        ).decimals();
        require(
            _newLoanAmountBorrowed >=
                (IMarketRegistry(address(this)).getMinLoanAmountAllowed() *
                    (10 ** stableCoinDecimals)),
            "GLM: min loan amount invalid"
        );
        require(
            loanDetails.borrower == LibMeta._msgSender(),
            "GLM, Only Borrow Adjust Loan"
        );

        (, , uint256 collatetralInBorrowed) = LibTokenMarket.getltvCalculations(
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            loanDetails.loanAmountInBorrowed,
            loanDetails.borrower,
            loanDetails.tierType
        );
        uint256 response = IUserTier(address(this)).isCreateLoanTokenUnderTier(
            LibMeta._msgSender(),
            _newLoanAmountBorrowed,
            collatetralInBorrowed,
            loanDetails.stakedCollateralTokens,
            loanDetails.tierType
        );
        require(response == 200, "offer not under tier");

        loanDetails = LibMarketStorage.LoanDetailsToken(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            _isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            LibMarketStorage.LoanStatus.INACTIVE,
            LibMeta._msgSender(),
            0,
            loanDetails.isMintSp,
            loanDetails.tierType,
            block.timestamp + 20 seconds,
            loanDetails.ltvpercentage
        );

        ms.borrowerLoanToken[_loanIdAdjusted] = loanDetails;

        emit LibTokenMarket.LoanOfferAdjustedToken(
            _loanIdAdjusted,
            loanDetails
        );
    }

    /// @dev function to cancel the created laon offer for token type Single || Multi Token Colletrals
    /// @param _loanId loan Id which is being cancelled/removed, will update the status of the loan details from the mapping

    function tokenLoanOfferCancel(uint256 _loanId) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            ms.borrowerLoanToken[_loanId].loanStatus ==
                LibMarketStorage.LoanStatus.INACTIVE,
            "GLM, Loan cannot be cancel"
        );
        require(
            ms.borrowerLoanToken[_loanId].borrower == LibMeta._msgSender(),
            "GLM, Only Borrow can cancel"
        );

        ms.borrowerLoanToken[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .CANCELLED;
        emit LibTokenMarket.LoanOfferCancelToken(
            _loanId,
            LibMeta._msgSender(),
            ms.borrowerLoanToken[_loanId].loanStatus
        );
    }

    /// @dev cancel multiple loans by liquidator
    /// @dev function to cancel loans which are invalid,
    /// @dev because of low ltv or max loan amount below the collateral value, or duplicated loans on same collateral amount

    function tokenLoanCancelBulk(
        uint256[] memory _loanIds
    ) external onlyLiquidator(LibMeta._msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        uint256 loanIdsLength = _loanIds.length;
        for (uint256 i = 0; i < loanIdsLength; i++) {
            require(
                ms.borrowerLoanToken[_loanIds[i]].loanStatus ==
                    LibMarketStorage.LoanStatus.INACTIVE,
                "GLM, Loan cannot be cancel"
            );

            ms.borrowerLoanToken[_loanIds[i]].loanStatus = LibMarketStorage
                .LoanStatus
                .CANCELLED;
            emit LibTokenMarket.LoanOfferCancelToken(
                _loanIds[i],
                ms.borrowerLoanToken[_loanIds[i]].borrower,
                ms.borrowerLoanToken[_loanIds[i]].loanStatus
            );
        }
    }

    /// @dev function for lender to activate loan offer by the borrower
    /// @param loanIds array of loan ids which are going to be activated
    /// @param stableCoinAmounts amounts of stable coin requested by the borrower for the specific loan Id
    /// @param _autoSell if autosell, then loan will be autosell at the time of liquidation through the DEX

    function activateLoanToken(
        uint256[] memory loanIds,
        uint256[] memory stableCoinAmounts,
        bool[] memory _autoSell
    ) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            loanIds.length == stableCoinAmounts.length &&
                loanIds.length == _autoSell.length,
            "GLM: length not match"
        );

        for (uint256 i = 0; i < loanIds.length; i++) {
            LibMarketStorage.LoanDetailsToken storage loanDetails = ms
                .borrowerLoanToken[loanIds[i]];

            require(
                block.timestamp > loanDetails.unlockTime,
                "Loan is timed locked"
            );

            require(
                loanDetails.loanStatus == LibMarketStorage.LoanStatus.INACTIVE,
                "GLM, not inactive"
            );

            loanDetails.loanStatus = LibMarketStorage.LoanStatus.ACTIVE;

            //push active loan ids to the lendersactivatedloanIds mapping
            ms.activatedLoanIdsToken[LibMeta._msgSender()].push(loanIds[i]);
            require(
                loanDetails.borrower != LibMeta._msgSender(),
                "GLM, self activation forbidden"
            );
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

            for (
                uint256 j = 0;
                j < loanDetails.stakedCollateralTokens.length;
                j++
            ) {
                if (
                    IClaimToken(address(this)).isClaimToken(
                        IClaimToken(address(this)).getClaimTokenofSUNToken(
                            loanDetails.stakedCollateralTokens[j]
                        )
                    )
                ) {
                    require(
                        !_autoSell[i],
                        "GTM: autosell should be false for SUN Collateral Token"
                    );
                }
            }

            (
                uint256 collateralLTVPercentage,
                uint256 maxLoanAmount,

            ) = LibTokenMarket.getltvCalculations(
                    loanDetails.stakedCollateralTokens,
                    loanDetails.stakedCollateralAmounts,
                    loanDetails.borrowStableCoin,
                    stableCoinAmounts[i],
                    loanDetails.borrower,
                    loanDetails.tierType
                );

            require(
                maxLoanAmount != 0,
                "GTM: borrower not eligible, no tierLevel"
            );

            require(
                collateralLTVPercentage > loanDetails.ltvpercentage,
                "GLM: Can not activate loan at liquidation level."
            );

            /// @dev  if maxLoanAmount is greater then we will keep setting the borrower loan offer amount in the loan Details
            if (maxLoanAmount < loanDetails.loanAmountInBorrowed) {
                // maxLoanAmount is now assigning in the loan Details struct
                require(
                    stableCoinAmounts[i] <= maxLoanAmount &&
                        stableCoinAmounts[i] >
                        maxLoanAmount - ((maxLoanAmount * 3) / 100),
                    "GLM: loan amount not equal maxLoanAmount"
                );
                loanDetails.loanAmountInBorrowed = stableCoinAmounts[i];
            }

            uint256 apyFee = LibMarketProvider.getAPYFee(
                loanDetails.loanAmountInBorrowed,
                loanDetails.apyOffer,
                loanDetails.termsLengthInDays
            );
            uint256 platformFee = (loanDetails.loanAmountInBorrowed *
                (IProtocolRegistry(address(this)).getGovPlatformFee())) /
                (10000);

            //adding platform fee
            ms.stableCoinWithdrawable[
                loanDetails.borrowStableCoin
            ] += platformFee;

            //activated loan id to the lender details
            ms.activatedLoanToken[loanIds[i]] = LibMarketStorage.LenderDetails({
                lender: LibMeta._msgSender(),
                activationLoanTimeStamp: block.timestamp,
                autoSell: _autoSell[i]
            });

            {
                //checking again the collateral tokens approval from the borrower
                //contract will now hold the staked collateral tokens
                require(
                    LibTokenMarket.transferCollateralsandMintSynthetic(
                        loanIds[i],
                        loanDetails.stakedCollateralTokens,
                        loanDetails.stakedCollateralAmounts,
                        loanDetails.borrower
                    ),
                    "Transfer Collateral Failed"
                );

                /// @dev approving erc20 stable token from the front end
                /// @dev transfer platform fee and apy fee to th liquidator contract, before  transfering the stable coins to borrower.
                IERC20(loanDetails.borrowStableCoin).safeTransferFrom(
                    LibMeta._msgSender(),
                    address(this),
                    loanDetails.loanAmountInBorrowed
                );
                /// @dev loan amount transfer after cut to borrower
                IERC20(loanDetails.borrowStableCoin).safeTransfer(
                    loanDetails.borrower,
                    (loanDetails.loanAmountInBorrowed - (apyFee + platformFee))
                );
            }

            emit LibTokenMarket.TokenLoanOfferActivated(
                loanIds[i],
                LibMeta._msgSender(),
                loanDetails.loanAmountInBorrowed - (apyFee + platformFee),
                _autoSell[i]
            );
        }
    }

    /// @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
    /// @param _loanId loan Id of the borrower
    /// @return LoanDetailsToken.LenderDetails returns the activate loan detail
    function getActivatedLoanDetailsToken(
        uint256 _loanId
    ) external view returns (LibMarketStorage.LenderDetails memory) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        return ms.activatedLoanToken[_loanId];
    }

    /// @dev get loan details of the single or multi-token
    /// @param _loanId loan Id of the borrower
    /// @return LoanDetailsToken returns the activate loan detail
    function getLoanOffersToken(
        uint256 _loanId
    ) external view returns (LibMarketStorage.LoanDetailsToken memory) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        return ms.borrowerLoanToken[_loanId];
    }

    function getltvCalculations(
        address[] memory _stakedCollateralTokens,
        uint256[] memory _stakedCollateralAmount,
        address _borrowStableCoin,
        uint256 _loanAmountinStable,
        address _borrower,
        LibMarketStorage.TierType _tierType
    )
        external
        view
        returns (
            uint256 calculatedLTV,
            uint256 maxLoanAmountValue,
            uint256 collatetralInBorrowed
        )
    {
        return
            LibTokenMarket.getltvCalculations(
                _stakedCollateralTokens,
                _stakedCollateralAmount,
                _borrowStableCoin,
                _loanAmountinStable,
                _borrower,
                _tierType
            );
    }
}
