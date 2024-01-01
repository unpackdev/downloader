// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./LibAppStorage.sol";
import "./LibMarketStorage.sol";

import "./IMarketRegistry.sol";

import "./LibNFTMarket.sol";
import "./IUserTier.sol";
import "./LibMarketProvider.sol";
import "./LibMeta.sol";
import "./IProtocolRegistry.sol";

contract NFTMarketFacet is Modifiers, ERC721Holder {
    using SafeERC20 for IERC20;

    /// @dev function to create Single || Multi NFT Loan Offer by the BORROWER
    /// @param  loanDetailsNFT {see LibMarketStorage.sol}

    function createLoanNft(
        LibMarketStorage.LoanDetailsNFTData memory loanDetailsNFT
    ) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            IProtocolRegistry(address(this)).isStableApproved(
                loanDetailsNFT.borrowStableCoin
            ),
            "GLM: not approved stable coin"
        );

        uint256 newLoanIdNFT = ms.loanIdNft + 1;
        uint256 stableCoinDecimals = IERC20Metadata(
            loanDetailsNFT.borrowStableCoin
        ).decimals();
        require(
            loanDetailsNFT.loanAmountInBorrowed >=
                (IMarketRegistry(address(this)).getMinLoanAmountAllowed() *
                    (10 ** stableCoinDecimals)),
            "GLM: min loan amount invalid"
        );

        uint256 collateralLength = loanDetailsNFT
            .stakedCollateralNFTsAddress
            .length;
        require(
            collateralLength <=
                IMarketRegistry(address(this)).getMultiCollateralLimit(),
            "GLM: Collateral Length Exceeded"
        );
        require(
            (loanDetailsNFT.stakedCollateralNFTsAddress.length ==
                loanDetailsNFT.stakedCollateralNFTId.length) ==
                (loanDetailsNFT.stakedCollateralNFTId.length ==
                    loanDetailsNFT.stakedNFTPrice.length),
            "GLM: Length not equal"
        );

        uint256 collatetralInBorrowed = 0;
        for (uint256 index = 0; index < collateralLength; index++) {
            collatetralInBorrowed += loanDetailsNFT.stakedNFTPrice[index];
        }
        uint256 response = IUserTier(address(this)).isCreateLoanNftUnderTier(
            LibMeta._msgSender(),
            loanDetailsNFT.loanAmountInBorrowed,
            collatetralInBorrowed,
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.tierType
        );
        require(response == 200, "offer not under tier");
        ms.borrowerLoanIdsNFT[LibMeta._msgSender()].push(newLoanIdNFT);
        //loop through all staked collateral NFTs.
        require(
            LibNFTMarket.checkApprovalNFTs(
                loanDetailsNFT.stakedCollateralNFTsAddress,
                loanDetailsNFT.stakedCollateralNFTId
            ),
            "GLM: one or more nfts not approved"
        );

        ms.borrowerLoanNFT[newLoanIdNFT] = LibMarketStorage.LoanDetailsNFT(
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.stakedCollateralNFTId,
            loanDetailsNFT.stakedNFTPrice,
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            LibMarketStorage.LoanStatus.INACTIVE,
            loanDetailsNFT.termsLengthInDays,
            loanDetailsNFT.isInsured,
            LibMeta._msgSender(),
            loanDetailsNFT.borrowStableCoin,
            loanDetailsNFT.tierType,
            0,
            IMarketRegistry(address(this)).getLTVPercentage()
        );

        emit LibNFTMarket.LoanOfferCreatedNFT(
            newLoanIdNFT,
            ms.borrowerLoanNFT[newLoanIdNFT]
        );

        ms.loanIdNft++;
    }

    /// @dev function to cancel the created laon offer for token type Single || Multi NFT Colletrals
    /// @param _nftloanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping

    function nftloanOfferCancel(uint256 _nftloanId) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        require(
            ms.borrowerLoanNFT[_nftloanId].loanStatus ==
                LibMarketStorage.LoanStatus.INACTIVE,
            "GLM, cannot be cancel"
        );
        require(
            ms.borrowerLoanNFT[_nftloanId].borrower == LibMeta._msgSender(),
            "GLM, only borrower can cancel"
        );

        ms.borrowerLoanNFT[_nftloanId].loanStatus = LibMarketStorage
            .LoanStatus
            .CANCELLED;

        emit LibNFTMarket.LoanOfferCancelNFT(
            _nftloanId,
            LibMeta._msgSender(),
            ms.borrowerLoanNFT[_nftloanId].loanStatus
        );
    }

    // @dev cancel multiple loans by liquidator
    /// @dev function to cancel loans which are invalid,
    /// @dev because of low ltv or max loan amount below the collateral value, or duplicated loans on same collateral amount
    function nftLoanCancelBulk(
        uint256[] memory _loanIds
    ) external onlyLiquidator(LibMeta._msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        uint256 loanIdsLength = _loanIds.length;
        for (uint256 i = 0; i < loanIdsLength; i++) {
            require(
                ms.borrowerLoanNFT[_loanIds[i]].loanStatus ==
                    LibMarketStorage.LoanStatus.INACTIVE,
                "GLM, Loan cannot be cancel"
            );

            ms.borrowerLoanNFT[_loanIds[i]].loanStatus = LibMarketStorage
                .LoanStatus
                .CANCELLED;
            emit LibNFTMarket.LoanOfferCancelNFT(
                _loanIds[i],
                ms.borrowerLoanNFT[_loanIds[i]].borrower,
                ms.borrowerLoanNFT[_loanIds[i]].loanStatus
            );
        }
    }

    /// @dev function to adjust already created loan offer, while in inactive state
    /// @param  _nftloanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    /// @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    /// @param _newTermsLengthInDays, borrower changing the loan term in days
    /// @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    /// @param _isInsured, isinsured true or false

    function updateNftLoan(
        uint256 _nftloanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint256 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isInsured
    ) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsNFT storage loanDetailsNFT = ms
            .borrowerLoanNFT[_nftloanIdAdjusted];

        require(
            loanDetailsNFT.loanStatus == LibMarketStorage.LoanStatus.INACTIVE,
            "loan status has to be inactive"
        );
        require(
            loanDetailsNFT.borrower == LibMeta._msgSender(),
            "borrower not owner"
        );

        uint256 stableCoinDecimals = IERC20Metadata(
            loanDetailsNFT.borrowStableCoin
        ).decimals();

        require(
            _newLoanAmountBorrowed >=
                (IMarketRegistry(address(this)).getMinLoanAmountAllowed() *
                    (10 ** stableCoinDecimals)),
            "min loan amount invalid"
        );

        uint256 collatetralInBorrowed = 0;
        for (
            uint256 index = 0;
            index < loanDetailsNFT.stakedNFTPrice.length;
            index++
        ) {
            collatetralInBorrowed += ms
                .borrowerLoanNFT[_nftloanIdAdjusted]
                .stakedNFTPrice[index];
        }

        uint256 response = IUserTier(address(this)).isCreateLoanNftUnderTier(
            LibMeta._msgSender(),
            _newLoanAmountBorrowed,
            collatetralInBorrowed,
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.tierType
        );
        require(response == 200, "offer not under tier");
        ms.borrowerLoanNFT[_nftloanIdAdjusted] = LibMarketStorage
            .LoanDetailsNFT(
                loanDetailsNFT.stakedCollateralNFTsAddress,
                loanDetailsNFT.stakedCollateralNFTId,
                loanDetailsNFT.stakedNFTPrice,
                _newLoanAmountBorrowed,
                _newAPYOffer,
                LibMarketStorage.LoanStatus.INACTIVE,
                _newTermsLengthInDays,
                _isInsured,
                LibMeta._msgSender(),
                loanDetailsNFT.borrowStableCoin,
                loanDetailsNFT.tierType,
                block.timestamp + 20 seconds,
                loanDetailsNFT.ltvpercentage
            );

        emit LibNFTMarket.NFTLoanOfferAdjusted(
            _nftloanIdAdjusted,
            loanDetailsNFT
        );
    }

    /// @dev function for lender to activate loan offer by the borrower
    /// @param _nftloanId loan id which is going to be activated
    function activateNFTLoan(uint256 _nftloanId) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsNFT memory loanDetailsNFT = ms
            .borrowerLoanNFT[_nftloanId];

        require(
            block.timestamp > loanDetailsNFT.unlockTime,
            "Loan is timed locked"
        );

        require(
            loanDetailsNFT.loanStatus == LibMarketStorage.LoanStatus.INACTIVE,
            "GLM, loan should be InActive"
        );
        require(
            loanDetailsNFT.borrower != LibMeta._msgSender(),
            "GLM, only Lenders can Active"
        );

        ms.borrowerLoanNFT[_nftloanId].loanStatus = LibMarketStorage
            .LoanStatus
            .ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        ms.activatedLoanIdsNFTs[LibMeta._msgSender()].push(_nftloanId);

        uint256 platformFee = (loanDetailsNFT.loanAmountInBorrowed *
            (IProtocolRegistry(address(this)).getGovPlatformFee())) / 10000;

        ms.stableCoinWithdrawable[
            loanDetailsNFT.borrowStableCoin
        ] += platformFee;

        //activated loan id to the lender details
        ms.activatedLoanNFT[_nftloanId] = LibMarketStorage.LenderDetailsNFT({
            lender: LibMeta._msgSender(),
            activationLoanTimeStamp: block.timestamp
        });

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

        // checking again the collateral tokens approval from the borrower
        // contract will now hold the staked collateral tokens after safeTransferFrom executes
        require(
            LibNFTMarket.checkApprovedandTransferNFTs(
                loanDetailsNFT.stakedCollateralNFTsAddress,
                loanDetailsNFT.stakedCollateralNFTId,
                loanDetailsNFT.borrower
            ),
            "GTM: Transfer Failed"
        );

        uint256 apyFee = LibMarketProvider.getAPYFee(
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.termsLengthInDays
        );

        uint256 loanAmountAfterCut = loanDetailsNFT.loanAmountInBorrowed -
            (apyFee + platformFee);

        /// @dev lender transfer the stable coins to the nft market contract
        IERC20(loanDetailsNFT.borrowStableCoin).safeTransferFrom(
            LibMeta._msgSender(),
            address(this),
            loanDetailsNFT.loanAmountInBorrowed
        );

        /// @dev loan amount transfer to borrower after the loan amount cut
        IERC20(loanDetailsNFT.borrowStableCoin).safeTransfer(
            loanDetailsNFT.borrower,
            loanAmountAfterCut
        );

        emit LibNFTMarket.NFTLoanOfferActivated(
            _nftloanId,
            LibMeta._msgSender(),
            loanAmountAfterCut,
            loanDetailsNFT.termsLengthInDays,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.stakedCollateralNFTId,
            loanDetailsNFT.stakedNFTPrice,
            loanDetailsNFT.borrowStableCoin
        );
    }

    /// @dev payback loan full by the borrower to the lender
    /// @param _nftLoanId nft loan Id of the borrower
    function nftLoanPaybackBeforeTermEnd(
        uint256 _nftLoanId
    ) external whenNotPaused {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        address borrower = LibMeta._msgSender();

        LibMarketStorage.LoanDetailsNFT memory loanDetailsNFT = ms
            .borrowerLoanNFT[_nftLoanId];

        require(
            loanDetailsNFT.borrower == borrower,
            "GLM, only borrower can payback"
        );
        require(
            loanDetailsNFT.loanStatus == LibMarketStorage.LoanStatus.ACTIVE,
            "GLM, loan should be Active"
        );

        uint256 loanTermLengthPassed = block.timestamp -
            ms.activatedLoanNFT[_nftLoanId].activationLoanTimeStamp;

        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400; //86400 == 1 day
        require(
            loanTermLengthPassedInDays < loanDetailsNFT.termsLengthInDays + 1,
            "GLM: Loan already paybacked or liquidated"
        );
        uint256 apyFeeOriginal = LibMarketProvider.getAPYFee(
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.termsLengthInDays
        );

        uint256 earnedAPY = LibMarketProvider.getAPYFee(
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            loanTermLengthPassedInDays
        );

        uint256 finalAmounttoLender = loanDetailsNFT.loanAmountInBorrowed +
            earnedAPY;

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPY;

        ms.stableCoinWithdrawable[
            loanDetailsNFT.borrowStableCoin
        ] += unEarnedAPYFee;

        ms.borrowerLoanNFT[_nftLoanId].loanStatus = LibMarketStorage
            .LoanStatus
            .CLOSED;

        IERC20(loanDetailsNFT.borrowStableCoin).safeTransferFrom(
            loanDetailsNFT.borrower,
            address(this),
            loanDetailsNFT.loanAmountInBorrowed
        );

        IERC20(loanDetailsNFT.borrowStableCoin).safeTransfer(
            ms.activatedLoanNFT[_nftLoanId].lender,
            finalAmounttoLender
        );

        //loop through all staked collateral nft tokens.
        uint256 collateralNFTlength = loanDetailsNFT
            .stakedCollateralNFTsAddress
            .length;
        for (uint256 i = 0; i < collateralNFTlength; i++) {
            /// @dev contract will the repay staked collateral tokens to the borrower
            IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    address(this),
                    borrower,
                    loanDetailsNFT.stakedCollateralNFTId[i]
                );
        }

        emit LibNFTMarket.NFTLoanPaybacked(
            _nftLoanId,
            borrower,
            LibMarketStorage.LoanStatus.CLOSED
        );
    }

    /// @dev liquidate call by the gov world liqudatior address
    /// @param _loanId loan id to check if its loan term ended

    function liquidateBorrowerNFT(
        uint256 _loanId
    ) external onlyLiquidator(LibMeta._msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsNFT memory loanDetailsNFT = ms
            .borrowerLoanNFT[_loanId];
        LibMarketStorage.LenderDetailsNFT memory lenderDetails = ms
            .activatedLoanNFT[_loanId];

        require(
            loanDetailsNFT.loanStatus == LibMarketStorage.LoanStatus.ACTIVE,
            "GLM, loan should be Active"
        );

        uint256 loanTermLengthPassed = block.timestamp -
            lenderDetails.activationLoanTimeStamp;

        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400;

        uint256 apyFeeOriginal = LibMarketProvider.getAPYFee(
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.termsLengthInDays
        );

        uint256 earnedAPY = LibMarketProvider.getAPYFee(
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            loanTermLengthPassedInDays
        );

        if (earnedAPY > apyFeeOriginal) {
            earnedAPY = apyFeeOriginal;
        }

        require(
            loanTermLengthPassedInDays >= loanDetailsNFT.termsLengthInDays + 1,
            "GNM: Loan not ready for liquidation"
        );

        ms.borrowerLoanNFT[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .LIQUIDATED;

        IERC20(loanDetailsNFT.borrowStableCoin).safeTransfer(
            ms.activatedLoanNFT[_loanId].lender,
            earnedAPY
        );
        //send collateral nfts to the lender
        uint256 collateralNFTlength = loanDetailsNFT
            .stakedCollateralNFTsAddress
            .length;
        for (uint256 i = 0; i < collateralNFTlength; i++) {
            //contract will the repay staked collateral tokens to the lender
            IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    address(this),
                    lenderDetails.lender,
                    loanDetailsNFT.stakedCollateralNFTId[i]
                );
        }

        emit LibNFTMarket.AutoLiquidatedNFT(
            _loanId,
            LibMarketStorage.LoanStatus.LIQUIDATED
        );
    }

    function getActivatedNFTLoanOffers(
        uint256 _loanId
    ) external view returns (LibMarketStorage.LenderDetailsNFT memory) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        return ms.activatedLoanNFT[_loanId];
    }

    function getLoanOfferNFT(
        uint256 _loanId
    ) external view returns (LibMarketStorage.LoanDetailsNFT memory) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        return ms.borrowerLoanNFT[_loanId];
    }
}
