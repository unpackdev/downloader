// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IBToken.sol";
import "./IDebtToken.sol";
import "./ILendPoolLoan.sol";
import "./ILendPoolLiquidator.sol";
import "./INFTOracleGetter.sol";
import "./Errors.sol";
import "./WadRayMath.sol";
import "./GenericLogic.sol";
import "./PercentageMath.sol";
import "./ReserveLogic.sol";
import "./NftLogic.sol";
import "./ValidationLogic.sol";
import "./ReserveConfiguration.sol";
import "./NftConfiguration.sol";
import "./DataTypes.sol";
import "./LendPoolStorage.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";

/**
 * @title LendPoolLiquidator contract
 * @dev Implements the actions involving management of liquidation in the Protocol
 * - Users can:
 *   # Auction
 *   # Redeem
 *   # Liquidate
 * IMPORTANT This contract will run always via DELEGATECALL, through the LendPool, so the chain of inheritance
 * is the same as the LendPool, to have compatible storage layouts
 
 **/
contract LendPoolLiquidator is
    Initializable,
    ILendPoolLiquidator,
    LendPoolStorage,
    ContextUpgradeable
{
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using NftLogic for DataTypes.NftData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using NftConfiguration for DataTypes.NftConfigurationMap;

    struct AuctionLocalVars {
        address loanAddress;
        address initiator;
        uint256 loanId;
        uint256 thresholdPrice;
        uint256 liquidatePrice;
        uint256 borrowAmount;
        uint256 auctionEndTimestamp;
        uint256 minBidDelta;
    }

    /**
     * @dev Function to auction a non-healthy position collateral-wise
     * - Starts the Dutch action. The price starts reducing after this point.
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     **/
    function auction(address nftAsset, uint256 nftTokenId) external override {
        AuctionLocalVars memory vars;
        vars.initiator = _msgSender();

        vars.loanAddress = _addressesProvider.getLendPoolLoan();
        vars.loanId = ILendPoolLoan(vars.loanAddress).getCollateralLoanId(
            nftAsset,
            nftTokenId
        );
        require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

        DataTypes.LoanData memory loanData = ILendPoolLoan(vars.loanAddress)
            .getLoan(vars.loanId);

        DataTypes.ReserveData storage reserveData = _reserves[
            loanData.reserveAsset
        ];
        DataTypes.NftData storage nftData = _nfts[loanData.nftAsset];

        ValidationLogic.validateAuction(reserveData, nftData, loanData);

        // update state MUST BEFORE get borrow amount which is depent on latest borrow index
        reserveData.updateState();

        (
            vars.borrowAmount,
            vars.thresholdPrice,
            vars.liquidatePrice
        ) = GenericLogic.calculateLoanLiquidatePrice(
            vars.loanId,
            loanData.reserveAsset,
            reserveData,
            loanData.nftAsset,
            nftData,
            vars.loanAddress,
            _addressesProvider.getReserveOracle(),
            _addressesProvider.getNFTOracle()
        );

        require(
            vars.borrowAmount > vars.thresholdPrice,
            Errors.LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD
        );

        ILendPoolLoan(vars.loanAddress).auctionLoan(
            vars.initiator,
            vars.loanId,
            vars.borrowAmount,
            reserveData.variableBorrowIndex
        );

        // update interest rate according latest borrow amount (utilizaton)
        reserveData.updateInterestRates(
            loanData.reserveAsset,
            reserveData.bTokenAddress,
            0,
            0
        );

        emit Auction(
            vars.initiator,
            loanData.reserveAsset,
            nftAsset,
            nftTokenId,
            loanData.borrower,
            vars.loanId
        );
    }

    struct RedeemLocalVars {
        address initiator;
        address poolLoan;
        uint256 loanId;
        uint256 borrowAmount;
        uint256 repayAmount;
        uint256 minRepayAmount;
        uint256 maxRepayAmount;
        uint256 bidFine;
        uint256 redeemEndTimestamp;
    }

    struct LiquidateLocalVars {
        address poolLoan;
        address initiator;
        uint256 loanId;
        uint256 borrowAmount;
        uint256 extraAmount;
        uint256 remainAmount;
        uint256 auctionEndTimestamp;
        uint256 auctionPrice;
        uint256 liquidatePrice;
    }

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise
     * - The bidder buy collateral asset of the user getting liquidated, and receives
     *   the collateral asset
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     * @param onBehalfOf Address of liquidator. The Liquidated NFT will be sent to this address.
     **/
    function liquidate(
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        address treasury,
        uint256 interval,
        uint256 discountRate,
        uint256 treasuryFee
    )
        external
        override
        returns (
            // uint256 amount
            uint256
        )
    {
        LiquidateLocalVars memory vars;
        vars.initiator = _msgSender();

        vars.poolLoan = _addressesProvider.getLendPoolLoan();

        vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(
            nftAsset,
            nftTokenId
        );
        require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

        DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan)
            .getLoan(vars.loanId);

        DataTypes.ReserveData storage reserveData = _reserves[
            loanData.reserveAsset
        ];
        DataTypes.NftData storage nftData = _nfts[loanData.nftAsset];

        ValidationLogic.validateLiquidate(reserveData, nftData, loanData);

        // update state MUST BEFORE get borrow amount which is depent on latest borrow index
        reserveData.updateState();

        (vars.borrowAmount, , vars.liquidatePrice) = GenericLogic
            .calculateLoanLiquidatePrice(
                vars.loanId,
                loanData.reserveAsset,
                reserveData,
                loanData.nftAsset,
                nftData,
                vars.poolLoan,
                _addressesProvider.getReserveOracle(),
                _addressesProvider.getNFTOracle()
            );

        vars.auctionPrice = getAuctionPrice(
            loanData.bidStartTimestamp,
            interval,
            vars.liquidatePrice,
            discountRate,
            vars.borrowAmount
        );

        vars.extraAmount = vars.auctionPrice - vars.borrowAmount; //spillited to debtor and protocol

        ILendPoolLoan(vars.poolLoan).liquidateLoan(
            loanData.bidderAddress,
            vars.loanId,
            nftData.bNftAddress,
            vars.borrowAmount,
            reserveData.variableBorrowIndex
        );

        IDebtToken(reserveData.debtTokenAddress).burn(
            loanData.borrower,
            vars.borrowAmount,
            reserveData.variableBorrowIndex
        );

        // update interest rate according latest borrow amount (utilizaton)
        reserveData.updateInterestRates(
            loanData.reserveAsset,
            reserveData.bTokenAddress,
            vars.borrowAmount,
            0
        );

        // transfer borrow amount from lend pool to bToken, repay debt
        IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
            vars.initiator,
            reserveData.bTokenAddress,
            vars.borrowAmount
        );

        // transfer remain amount to borrower and protocol
        if (vars.extraAmount > 0) {
            uint256 treasuryFeeAmt = vars.extraAmount * treasuryFee / 10000;
            uint256 debtorAmt = vars.extraAmount - treasuryFeeAmt;

            IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                vars.initiator,
                loanData.borrower,
                debtorAmt
            );
            IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                vars.initiator,
                treasury,
                treasuryFeeAmt
            );
        }

        {
            uint256 _tokenId = nftTokenId;
            // transfer erc721 to bidder
            IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(
                address(this),
                onBehalfOf,
                _tokenId
            );
        }
        emit Liquidate(
            vars.initiator,
            loanData.reserveAsset,
            vars.borrowAmount,
            vars.remainAmount,
            loanData.nftAsset,
            loanData.nftTokenId,
            loanData.borrower,
            vars.loanId
        );

        return (vars.extraAmount);
    }

    function getAuctionPrice(
        uint256 startTimestamp,
        uint256 interval,
        uint256 liquidatePrice,
        uint256 discountRate,
        uint256 borrowAmount
    ) internal view returns (uint256 auctionPrice) {
        uint256 multiplier = (block.timestamp - startTimestamp) / interval;
        // uint discountRateInReserveDecimals = (10 ** reserveData.configuration.getDecimals()) * discountRate / 10000;
        uint256 discount = ((liquidatePrice * discountRate) / 10000) *
            multiplier;

        auctionPrice = discount < liquidatePrice //Discount can get more than liquidatePrice, so to prevent that
            ? liquidatePrice - discount
            : borrowAmount;

        //borrowed amount is the auction floor
        if (auctionPrice < borrowAmount) {
            auctionPrice = borrowAmount;
        }
    }
}
