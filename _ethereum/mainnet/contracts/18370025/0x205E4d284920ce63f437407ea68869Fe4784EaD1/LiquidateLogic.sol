// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IUToken.sol";
import "./IDebtToken.sol";
import "./IInterestRate.sol";
import "./ILendPoolAddressesProvider.sol";
import "./IReserveOracleGetter.sol";
import "./INFTOracleGetter.sol";
import "./ILendPoolLoan.sol";
import "./ILendPool.sol";
import "./ILockeyManager.sol";
import "./IDebtMarket.sol";

import "./ReserveLogic.sol";
import "./GenericLogic.sol";
import "./ValidationLogic.sol";

import "./ReserveConfiguration.sol";
import "./NftConfiguration.sol";
import "./PercentageMath.sol";
import "./Errors.sol";
import "./DataTypes.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";

/**
 * @title LiquidateLogic library
 * @author BendDao; Forked and edited by Unlockd
 * @notice Implements the logic to liquidate feature
 */
library LiquidateLogic {
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;
  /*//////////////////////////////////////////////////////////////
                          EVENTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Emitted when a borrower's loan is auctioned.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param bidPrice The price of the underlying reserve given by the bidder
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Auction(
    address user,
    address indexed reserve,
    uint256 bidPrice,
    address indexed nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted on redeem()
   * @param user The address of the user initiating the redeem(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param borrowAmount The borrow amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param loanId The loan ID of the NFT loans
   **/
  event Redeem(
    address user,
    address indexed reserve,
    uint256 borrowAmount,
    uint256 fineAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event Liquidate(
    address user,
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when an NFT is purchased via Buyout.
   * @param user The address of the user initiating the Buyout
   * @param reserve The address of the underlying asset of the reserve
   * @param buyoutAmount The amount of reserve paid by the buyer
   * @param borrowAmount The loan borrowed amount
   * @param nftAsset The amount of reserve received by the borrower
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The loan borrower address
   * @param onBehalfOf The receiver of the underlying NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Buyout(
    address user,
    address indexed reserve,
    uint256 buyoutAmount,
    uint256 borrowAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address borrower,
    address onBehalfOf,
    uint256 indexed loanId
  );
  /*//////////////////////////////////////////////////////////////
                          Structs
  //////////////////////////////////////////////////////////////*/
  struct AuctionLocalVars {
    address loanAddress;
    address reserveOracle;
    address nftOracle;
    address initiator;
    uint256 loanId;
    uint256 thresholdPrice;
    uint256 liquidatePrice;
    uint256 borrowAmount;
    uint256 auctionEndTimestamp;
    uint256 minBidDelta;
    uint256 extraAuctionDuration;
  }

  struct RedeemLocalVars {
    address initiator;
    address poolLoan;
    address reserveOracle;
    address nftOracle;
    address uToken;
    address debtMarket;
    uint256 loanId;
    uint256 borrowAmount;
    uint256 repayAmount;
    uint256 minRepayAmount;
    uint256 maxRepayAmount;
    uint256 bidFine;
    uint256 redeemEndTimestamp;
    uint256 minBidFinePct;
    uint256 minBidFine;
    uint256 extraRedeemDuration;
    uint256 liquidationThreshold;
  }

  struct LiquidateLocalVars {
    address initiator;
    address poolLoan;
    address reserveOracle;
    address nftOracle;
    address uToken;
    address debtMarket;
    uint256 loanId;
    uint256 borrowAmount;
    uint256 extraDebtAmount;
    uint256 remainAmount;
    uint256 auctionEndTimestamp;
    uint256 extraAuctionDuration;
  }

  struct BuyoutLocalVars {
    address initiator;
    address onBehalfOf;
    address poolLoan;
    address reserveOracle;
    address nftOracle;
    address debtMarket;
    uint256 loanId;
    uint256 borrowAmount;
    uint256 remainAmount;
    uint256 bidFine;
    uint256 nftPrice;
    address lockeysCollection;
    address lockeyManagerAddress;
    uint256 buyoutPrice;
    uint256 lockeyDiscount;
  }

  /*//////////////////////////////////////////////////////////////
                          MAIN LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Implements the auction feature. Through `auction()`, users auction assets in the protocol.
   * @dev Emits the `Auction()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param poolStates The state of the lend pool
   * @param params The additional parameters needed to execute the auction function
   */
  function executeAuction(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteLendPoolStates memory poolStates,
    DataTypes.ExecuteAuctionParams memory params
  ) external {
    require(params.onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    AuctionLocalVars memory vars;
    vars.initiator = params.initiator;

    vars.loanAddress = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();

    vars.loanId = ILendPoolLoan(vars.loanAddress).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.loanAddress).getLoan(vars.loanId);

    //Initiator can not bid for same onBehalfOf address, as the new auction would be the same as the currently existing auction
    //created by them previously. Nevertheless, it is possible for the initiator to bid for a different `onBehalfOf` address,
    //as the new bidderAddress will be different.
    require(params.onBehalfOf != loanData.bidderAddress, Errors.LP_CONSECUTIVE_BIDS_NOT_ALLOWED);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];

    ValidationLogic.validateAuction(reserveData, nftData, nftConfig, loanData, params.bidPrice);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, vars.thresholdPrice, ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.loanAddress,
      vars.reserveOracle,
      vars.nftOracle
    );

    // first time bid need to burn debt tokens and transfer reserve to uTokens
    if (loanData.state == DataTypes.LoanState.Active) {
      // loan's accumulated debt must exceed threshold (heath factor below 1.0)
      require(vars.borrowAmount > vars.thresholdPrice, Errors.LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD);

      // bid price must greater than borrow amount + delta (predicted compounded debt || fees)
      require(
        params.bidPrice >= vars.borrowAmount.percentMul(params.bidDelta),
        Errors.LPL_BID_PRICE_LESS_THAN_DEBT_PRICE
      );

      // bid price must greater than borrow amount plus timestamp configuration fee
      require(
        params.bidPrice >= (vars.borrowAmount + params.auctionDurationConfigFee),
        Errors.LPL_BID_PRICE_LESS_THAN_MIN_BID_REQUIRED
      );
    } else {
      // bid price must greater than borrow debt
      require(params.bidPrice >= vars.borrowAmount, Errors.LPL_BID_PRICE_LESS_THAN_BORROW);

      if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
        vars.extraAuctionDuration = poolStates.pauseDurationTime;
      }
      vars.auctionEndTimestamp =
        loanData.bidStartTimestamp +
        vars.extraAuctionDuration +
        (nftConfig.getAuctionDuration() * 1 minutes);
      require(block.timestamp <= vars.auctionEndTimestamp, Errors.LPL_BID_AUCTION_DURATION_HAS_END);

      // bid price must greater than highest bid + delta
      vars.minBidDelta = vars.borrowAmount.percentMul(PercentageMath.ONE_PERCENT);
      require(params.bidPrice >= (loanData.bidPrice + vars.minBidDelta), Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE);
    }

    ILendPoolLoan(vars.loanAddress).auctionLoan(
      vars.initiator,
      vars.loanId,
      params.onBehalfOf,
      params.bidPrice,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // lock highest bidder bid price amount to lend pool
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this), params.bidPrice);

    // transfer (return back) last bid price amount to previous bidder from lend pool
    if (loanData.bidderAddress != address(0)) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);
    }

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.uTokenAddress, 0, 0);

    emit Auction(
      vars.initiator,
      loanData.reserveAsset,
      params.bidPrice,
      params.nftAsset,
      params.nftTokenId,
      params.onBehalfOf,
      loanData.borrower,
      vars.loanId
    );
  }

  /**
   * @notice Implements the redeem feature. Through `redeem()`, users redeem assets in the protocol.
   * @dev Emits the `Redeem()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param poolStates The state of the lend pool
   * @param params The additional parameters needed to execute the redeem function
   */
  function executeRedeem(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteLendPoolStates memory poolStates,
    DataTypes.ExecuteRedeemParams memory params
  ) external returns (uint256) {
    RedeemLocalVars memory vars;
    vars.initiator = params.initiator;

    vars.poolLoan = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];

    ValidationLogic.validateRedeem(reserveData, nftData, nftConfig, loanData, params.amount);

    if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
      vars.extraRedeemDuration = poolStates.pauseDurationTime;
    }
    vars.redeemEndTimestamp = (loanData.bidStartTimestamp +
      vars.extraRedeemDuration +
      nftConfig.getRedeemDuration() *
      1 minutes);
    require(block.timestamp <= vars.redeemEndTimestamp, Errors.LPL_BID_REDEEM_DURATION_HAS_END);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.reserveOracle,
      vars.nftOracle
    );

    // check bid fine in min & max range
    (, vars.bidFine) = GenericLogic.calculateLoanBidFine(
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      nftConfig,
      loanData,
      vars.poolLoan,
      vars.reserveOracle
    );

    // check bid fine is enough
    require(vars.bidFine <= params.bidFine, Errors.LPL_INVALID_BID_FINE);

    vars.repayAmount = params.amount;

    // check the minimum debt repay amount, use liquidation threshold in config
    (, vars.liquidationThreshold, ) = nftConfig.getCollateralParams();

    vars.minRepayAmount = GenericLogic.calculateOptimalMinRedeemValue(
      vars.borrowAmount,
      params.nftAsset,
      params.nftTokenId,
      vars.nftOracle,
      vars.liquidationThreshold,
      params.safeHealthFactor
    );

    require(vars.repayAmount >= vars.minRepayAmount, Errors.LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD);

    // check the maxinmum debt repay amount
    vars.maxRepayAmount = GenericLogic.calculateOptimalMaxRedeemValue(vars.borrowAmount, vars.minRepayAmount);

    require(vars.repayAmount <= vars.maxRepayAmount, Errors.LP_AMOUNT_GREATER_THAN_MAX_REPAY);
    ILendPoolLoan(vars.poolLoan).redeemLoan(
      vars.initiator,
      vars.loanId,
      vars.repayAmount,
      reserveData.variableBorrowIndex
    );

    IDebtToken(reserveData.debtTokenAddress).burn(loanData.borrower, vars.repayAmount, reserveData.variableBorrowIndex);

    // Cancel debt listing if exist
    vars.debtMarket = addressesProvider.getAddress(keccak256("DEBT_MARKET"));
    if (IDebtMarket(vars.debtMarket).getDebtId(loanData.nftAsset, loanData.nftTokenId) != 0) {
      IDebtMarket(vars.debtMarket).cancelDebtListing(loanData.nftAsset, loanData.nftTokenId);
    }

    vars.uToken = reserveData.uTokenAddress;

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, vars.uToken, vars.repayAmount, 0);

    // transfer repay amount from borrower to uToken
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, vars.uToken, vars.repayAmount);

    // Deposit amount redeemed to lending protocol
    IUToken(vars.uToken).depositReserves(vars.repayAmount);

    if (loanData.bidderAddress != address(0)) {
      // transfer (return back) last bid price amount from lend pool to bidder
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);

      // transfer bid penalty fine amount from borrower to the first bidder
      IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
        vars.initiator,
        loanData.firstBidderAddress,
        vars.bidFine
      );
    }

    emit Redeem(
      vars.initiator,
      loanData.reserveAsset,
      vars.repayAmount,
      vars.bidFine,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.repayAmount + vars.bidFine);
  }

  /**
   * @notice Implements the liquidate feature. Through `liquidate()`, users liquidate assets in the protocol.
   * @dev Emits the `Liquidate()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param nftsConfig The state of the nft by tokenId
   * @param poolStates The state of the lend pool
   * @param params The additional parameters needed to execute the liquidate function
   */
  function executeLiquidate(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteLendPoolStates memory poolStates,
    DataTypes.ExecuteLiquidateParams memory params
  ) external returns (uint256) {
    LiquidateLocalVars memory vars;
    vars.initiator = params.initiator;

    vars.poolLoan = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];

    ValidationLogic.validateLiquidate(reserveData, nftData, nftConfig, loanData);

    // If pool paused after bidding start, add pool pausing time as extra auction duration
    if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
      vars.extraAuctionDuration = poolStates.pauseDurationTime;
    }
    vars.auctionEndTimestamp =
      loanData.bidStartTimestamp +
      vars.extraAuctionDuration +
      (nftConfig.getAuctionDuration() * 1 minutes);
    require(block.timestamp > vars.auctionEndTimestamp + 20 minutes, Errors.LPL_CLAIM_HASNT_STARTED_YET);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.reserveOracle,
      vars.nftOracle
    );

    // Last bid price can not cover borrow amount
    if (loanData.bidPrice < vars.borrowAmount) {
      vars.extraDebtAmount = vars.borrowAmount - loanData.bidPrice;
      require(params.amount >= vars.extraDebtAmount, Errors.LP_AMOUNT_LESS_THAN_EXTRA_DEBT);
    }

    if (loanData.bidPrice > vars.borrowAmount) {
      vars.remainAmount = loanData.bidPrice - vars.borrowAmount;
    }

    ILendPoolLoan(vars.poolLoan).liquidateLoan(
      loanData.bidderAddress,
      vars.loanId,
      nftData.uNftAddress,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    IDebtToken(reserveData.debtTokenAddress).burn(
      loanData.borrower,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // Cancel debt listing if exist
    vars.debtMarket = addressesProvider.getAddress(keccak256("DEBT_MARKET"));
    if (IDebtMarket(vars.debtMarket).getDebtId(loanData.nftAsset, loanData.nftTokenId) != 0) {
      IDebtMarket(vars.debtMarket).cancelDebtListing(loanData.nftAsset, loanData.nftTokenId);
    }

    vars.uToken = reserveData.uTokenAddress;

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, vars.uToken, vars.borrowAmount, 0);

    // transfer extra borrow amount from liquidator to lend pool
    if (vars.extraDebtAmount > 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this), vars.extraDebtAmount);
    }

    // transfer borrow amount from lend pool to uToken, repay debt
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(vars.uToken, vars.borrowAmount);

    // Deposit amount from debt repaid to lending protocol
    IUToken(vars.uToken).depositReserves(vars.borrowAmount);

    // transfer remain amount to borrower
    if (vars.remainAmount > 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.borrower, vars.remainAmount);
    }

    // transfer erc721 to bidder.
    //avoid DoS by transferring NFT to a malicious contract that reverts on ERC721 receive
    (bool success, ) = address(loanData.nftAsset).call(
      abi.encodeWithSignature(
        "safeTransferFrom(address,address,uint256)",
        address(this),
        loanData.bidderAddress,
        params.nftTokenId
      )
    );
    //If transfer was made to a malicious contract, send NFT to treasury
    if (!success)
      IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(
        address(this),
        IUToken(vars.uToken).RESERVE_TREASURY_ADDRESS(),
        params.nftTokenId
      );

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

    return (vars.extraDebtAmount);
  }

  /**
   * @notice Implements the buyout feature. Through `buyout()`, users buy NFTs currently deposited in the protocol.
   * @dev Emits the `Buyout()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param nftsConfig The state of the nft by tokenId
   * @param params The additional parameters needed to execute the buyout function
   */
  function executeBuyout(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteBuyoutParams memory params
  ) external {
    require(params.onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    BuyoutLocalVars memory vars;
    vars.initiator = params.initiator;
    vars.onBehalfOf = params.onBehalfOf;
    vars.poolLoan = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();
    vars.lockeysCollection = addressesProvider.getAddress(keccak256("LOCKEY_COLLECTION"));
    vars.lockeyManagerAddress = addressesProvider.getAddress(keccak256("LOCKEY_MANAGER"));

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);
    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];

    vars.nftPrice = INFTOracleGetter(vars.nftOracle).getNFTPrice(loanData.nftAsset, loanData.nftTokenId);

    reserveData.updateState();

    // Check for health factor
    (, , uint256 healthFactor) = GenericLogic.calculateLoanData(
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.loanId,
      vars.reserveOracle,
      vars.nftOracle
    );

    //Loan must be unhealthy in order to get liquidated
    require(
      healthFactor <= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.reserveOracle,
      vars.nftOracle
    );

    // Buyout price becomes maximum value between the borrow amount and the NFT price
    vars.buyoutPrice = vars.borrowAmount > vars.nftPrice ? vars.borrowAmount : vars.nftPrice;

    (, vars.bidFine) = GenericLogic.calculateLoanBidFine(
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      nftConfig,
      loanData,
      vars.poolLoan,
      vars.reserveOracle
    );

    ValidationLogic.validateBuyout(reserveData, nftData, nftConfig, loanData);

    vars.lockeyDiscount = vars.nftPrice.percentMul(
      ILockeyManager(vars.lockeyManagerAddress).getLockeyDiscountPercentage()
    );

    // This should only happen if a user holds a lockey and the lockeyDiscount is higher than the borrowed Amount
    if (
      vars.lockeyDiscount > vars.borrowAmount &&
      IERC721Upgradeable(vars.lockeysCollection).balanceOf(vars.onBehalfOf) != 0
    ) {
      vars.buyoutPrice = vars.lockeyDiscount;
    }

    ILendPoolLoan(vars.poolLoan).buyoutLoan(
      loanData.bidderAddress,
      vars.loanId,
      nftData.uNftAddress,
      vars.borrowAmount,
      reserveData.variableBorrowIndex,
      vars.buyoutPrice
    );

    IDebtToken(reserveData.debtTokenAddress).burn(
      loanData.borrower,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // Cancel debt listing if exist
    vars.debtMarket = addressesProvider.getAddress(keccak256("DEBT_MARKET"));
    if (IDebtMarket(vars.debtMarket).getDebtId(loanData.nftAsset, loanData.nftTokenId) != 0) {
      IDebtMarket(vars.debtMarket).cancelDebtListing(loanData.nftAsset, loanData.nftTokenId);
    }

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.uTokenAddress, vars.borrowAmount, 0);

    //Transfer buyout amount to lendpool
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this), vars.buyoutPrice);

    // transfer borrow amount from lend pool to uToken, repay debt
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(reserveData.uTokenAddress, vars.borrowAmount);

    // Deposit amount from debt repaid to lending protocol
    IUToken(reserveData.uTokenAddress).depositReserves(vars.borrowAmount);

    vars.remainAmount = vars.buyoutPrice - vars.borrowAmount;

    // In case the NFT has bids, transfer (give back) bid amount to bidder, and send incentive fine to first bidder
    if (loanData.bidderAddress != address(0)) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);
      // Remaining amount can cover the bid fine.
      if (vars.remainAmount >= vars.bidFine) {
        vars.remainAmount -= vars.bidFine;
        IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.firstBidderAddress, vars.bidFine);
      } else if (vars.remainAmount > 0) {
        // Remaining amount can not cover the bid fine, but it is greater than 0
        IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.firstBidderAddress, vars.remainAmount);
        delete vars.remainAmount;
      }
    }

    // transfer remain amount to borrower
    if (vars.remainAmount != 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.borrower, vars.remainAmount);
    }

    // transfer erc721 to buyer.
    //avoid DoS by transferring NFT to a malicious contract that reverts on ERC721 receive
    (bool success, ) = address(loanData.nftAsset).call(
      abi.encodeWithSignature(
        "safeTransferFrom(address,address,uint256)",
        address(this),
        vars.onBehalfOf,
        params.nftTokenId
      )
    );
    //If transfer was made to a malicious contract, send NFT to treasury
    if (!success)
      IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(
        address(this),
        IUToken(reserveData.uTokenAddress).RESERVE_TREASURY_ADDRESS(),
        params.nftTokenId
      );
    {
      emit Buyout(
        vars.initiator,
        loanData.reserveAsset,
        vars.buyoutPrice,
        vars.borrowAmount,
        loanData.nftAsset,
        loanData.nftTokenId,
        loanData.borrower,
        vars.onBehalfOf,
        vars.loanId
      );
    }
  }
}
