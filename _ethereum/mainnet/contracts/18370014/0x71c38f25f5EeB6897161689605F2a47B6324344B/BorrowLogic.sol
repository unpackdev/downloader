// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IUToken.sol";
import "./IDebtToken.sol";
import "./IInterestRate.sol";
import "./ILendPoolAddressesProvider.sol";
import "./IReserveOracleGetter.sol";
import "./INFTOracleGetter.sol";
import "./ILendPoolLoan.sol";
import "./IDebtMarket.sol";
import "./ReserveConfiguration.sol";
import "./MathUtils.sol";
import "./WadRayMath.sol";
import "./PercentageMath.sol";
import "./Errors.sol";
import "./DataTypes.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";

import "./ReserveLogic.sol";
import "./GenericLogic.sol";
import "./ValidationLogic.sol";

/**
 * @title BorrowLogic library
 * @author BendDao; Forked and edited by Unlockd
 * @notice Implements the logic to borrow feature
 */
library BorrowLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;
  /*//////////////////////////////////////////////////////////////
                          EVENTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Emitted on borrow() when loan needs to be opened
   * @param user The address of the user initiating the borrow(), receiving the funds
   * @param reserve The address of the underlying asset being borrowed
   * @param amount The amount borrowed out
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the loan
   * @param referral The referral code used
   **/
  event Borrow(
    address user,
    address indexed reserve,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address indexed onBehalfOf,
    uint256 borrowRate,
    uint256 loanId,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param user The address of the user initiating the repay(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param amount The amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The beneficiary of the repayment, getting his debt reduced
   * @param loanId The loan ID of the NFT loans
   **/
  event Repay(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );
  /*//////////////////////////////////////////////////////////////
                          Structs
  //////////////////////////////////////////////////////////////*/
  struct ExecuteBorrowLocalVars {
    address initiator;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 loanId;
    address reserveOracle;
    address nftOracle;
    address loanAddress;
    uint256 totalSupply;
  }

  struct RepayLocalVars {
    address initiator;
    address poolLoan;
    address onBehalfOf;
    uint256 loanId;
    bool isUpdate;
    uint256 borrowAmount;
    uint256 repayAmount;
  }

  /*//////////////////////////////////////////////////////////////
                          MAIN LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Implements the borrow feature. Through `borrow()`, users borrow assets from the protocol.
   * @dev Emits the `Borrow()` event.
   * @param addressesProvider The addresses provider
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param params The additional parameters needed to execute the borrow function
   */
  function executeBorrow(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteBorrowParams memory params
  ) external {
    _borrow(addressesProvider, reservesData, nftsData, nftsConfig, params);
  }

  /**
   * @notice Implements the repay feature. Through `repay()`, users repay assets to the protocol.
   * @dev Emits the `Repay()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of nfts
   * @param params The additional parameters needed to execute the repay function
   */
  function executeRepay(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteRepayParams memory params
  ) external returns (uint256, bool) {
    return _repay(addressesProvider, reservesData, nftsData, nftsConfig, params);
  }

  /*//////////////////////////////////////////////////////////////
                          INTERNALS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Implements the borrow feature. Through `_borrow()`, users borrow assets from the protocol.
   * @dev Emits the `Borrow()` event.
   * @param addressesProvider The addresses provider
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param params The additional parameters needed to execute the borrow function
   */
  function _borrow(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteBorrowParams memory params
  ) internal {
    require(params.onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    ExecuteBorrowLocalVars memory vars;
    vars.initiator = params.initiator;

    DataTypes.ReserveData storage reserveData = reservesData[params.asset];
    DataTypes.NftData storage nftData = nftsData[params.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[params.nftAsset][params.nftTokenId];

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();
    // Convert asset amount to ETH
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();
    vars.loanAddress = addressesProvider.getLendPoolLoan();
    address debtMarket = addressesProvider.getAddress(keccak256("DEBT_MARKET"));

    vars.loanId = ILendPoolLoan(vars.loanAddress).getCollateralLoanId(params.nftAsset, params.nftTokenId);

    ValidationLogic.validateBorrow(
      params,
      reserveData,
      nftData,
      nftConfig,
      vars.loanAddress,
      vars.loanId,
      vars.reserveOracle,
      vars.nftOracle
    );

    address uToken = reserveData.uTokenAddress;

    require(IUToken(uToken).getAvailableLiquidity() >= params.amount, Errors.LP_RESERVES_WITHOUT_ENOUGH_LIQUIDITY);

    if (vars.loanId == 0) {
      IERC721Upgradeable(params.nftAsset).safeTransferFrom(vars.initiator, address(this), params.nftTokenId);

      vars.loanId = ILendPoolLoan(vars.loanAddress).createLoan(
        vars.initiator,
        params.onBehalfOf,
        params.nftAsset,
        params.nftTokenId,
        nftData.uNftAddress,
        params.asset,
        params.amount,
        reserveData.variableBorrowIndex
      );
    } else {
      ILendPoolLoan(vars.loanAddress).updateLoan(
        vars.initiator,
        vars.loanId,
        params.amount,
        0,
        reserveData.variableBorrowIndex
      );

      uint256 debtId = IDebtMarket(debtMarket).getDebtId(params.nftAsset, params.nftTokenId);
      if (debtId != 0) {
        IDebtMarket(debtMarket).cancelDebtListing(params.nftAsset, params.nftTokenId);
      }
    }

    IDebtToken(reserveData.debtTokenAddress).mint(
      vars.initiator,
      params.onBehalfOf,
      params.amount,
      reserveData.variableBorrowIndex
    );

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(params.asset, uToken, 0, params.amount);

    // Withdraw amount from external lending protocol
    uint256 value = IUToken(uToken).withdrawReserves(params.amount);

    // Transfer underlying to user
    IUToken(uToken).transferUnderlyingTo(vars.initiator, value);

    emit Borrow(
      vars.initiator,
      params.asset,
      value,
      params.nftAsset,
      params.nftTokenId,
      params.onBehalfOf,
      reserveData.currentVariableBorrowRate,
      vars.loanId,
      params.referralCode
    );
  }

  /**
   * @notice Implements the repay feature. Through `repay()`, users repay assets to the protocol.
   * @dev Emits the `Repay()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param params The additional parameters needed to execute the repay function
   */
  function _repay(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteRepayParams memory params
  ) internal returns (uint256, bool) {
    RepayLocalVars memory vars;
    vars.initiator = params.initiator;

    vars.poolLoan = addressesProvider.getLendPoolLoan();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[params.nftAsset][params.nftTokenId];

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (, vars.borrowAmount) = ILendPoolLoan(vars.poolLoan).getLoanReserveBorrowAmount(vars.loanId);

    ValidationLogic.validateRepay(reserveData, nftData, nftConfig, loanData, params.amount, vars.borrowAmount);

    vars.repayAmount = vars.borrowAmount;
    vars.isUpdate = false;
    if (params.amount < vars.repayAmount) {
      vars.isUpdate = true;
      vars.repayAmount = params.amount;
    }

    // Cancel debt listing if exist
    address debtMarket = addressesProvider.getAddress(keccak256("DEBT_MARKET"));
    uint256 debtId = IDebtMarket(debtMarket).getDebtId(params.nftAsset, params.nftTokenId);
    if (debtId != 0) {
      IDebtMarket(debtMarket).cancelDebtListing(params.nftAsset, params.nftTokenId);
    }

    if (vars.isUpdate) {
      ILendPoolLoan(vars.poolLoan).updateLoan(
        vars.initiator,
        vars.loanId,
        0,
        vars.repayAmount,
        reserveData.variableBorrowIndex
      );
    } else {
      ILendPoolLoan(vars.poolLoan).repayLoan(
        vars.initiator,
        vars.loanId,
        nftData.uNftAddress,
        vars.repayAmount,
        reserveData.variableBorrowIndex
      );
    }

    IDebtToken(reserveData.debtTokenAddress).burn(loanData.borrower, vars.repayAmount, reserveData.variableBorrowIndex);

    address uToken = reserveData.uTokenAddress;

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, uToken, vars.repayAmount, 0);

    // transfer repay amount to uToken
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, uToken, vars.repayAmount);

    // Deposit amount repaid to external lending protocol
    IUToken(uToken).depositReserves(vars.repayAmount);

    // transfer erc721 to borrower
    if (!vars.isUpdate) {
      IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(address(this), loanData.borrower, params.nftTokenId);
    }

    emit Repay(
      vars.initiator,
      loanData.reserveAsset,
      vars.repayAmount,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.repayAmount, !vars.isUpdate);
  }
}
