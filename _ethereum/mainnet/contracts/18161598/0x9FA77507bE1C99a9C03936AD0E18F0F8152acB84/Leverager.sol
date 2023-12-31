// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IERC4626.sol";
import "./ILeverager.sol";
import "./IPool.sol";
import "./IPoolAddressesProvider.sol";
import "./IPoolDataProvider.sol";
import "./IPriceOracle.sol";
import "./FlashLoanSimpleReceiverBase.sol";
import "./PercentageMath.sol";

enum Action {
  Open,
  Close
}

// use Aave v3 flashloan
contract Leverager is ILeverager, FlashLoanSimpleReceiverBase, Ownable {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;

  /* ============ Constants ============ */
  uint16 internal constant REFERRAL_CODE = 0;
  uint256 internal constant INTEREST_RATE_MODE = 2;
  address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // Address of the asset to be supplied to yield protocol
  address internal constant SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA; // Address of the asset to be deposited

  /* ============ State Variables ============ */
  address internal _debtAsset; // Address of the asset to be borrowed
  // Address of a dex router (e.g., Uniswap, 1Inch).
  address internal _router;
  address internal _treasuryAddress; // 20
  // Fee of the protocol, expressed in basis points (bps).
  uint256 internal _protocolFee;
  // Ratio of the amount to be withdrawn from Aave v3 to not touch liquidation threshold.
  uint256 internal _withdrawalRatio;

  struct FlashLoanVars {
    address router;
    address debtAsset;
    uint256 supplyAmount;
    uint256 depositAmount;
    uint256 borrowAmount;
    uint256 repayAmount;
    uint256 withdrawnAmount;
    uint256 protocolFee;
    IPool aave;
  }

  constructor(
    IPoolAddressesProvider provider,
    address debtAsset,
    address router,
    address treasuryAddress,
    uint256 protocolFee,
    uint256 withdrawalRatio
  ) FlashLoanSimpleReceiverBase(provider) {
    _debtAsset = debtAsset;
    _router = router;
    _treasuryAddress = treasuryAddress;
    _protocolFee = protocolFee;
    _withdrawalRatio = withdrawalRatio;
  }

  /* ============ External Functions ============ */

  /**
   * @dev Initiates a flashloan leveraging mechanism to open a position.
   * @notice Users must approve this contract for DAI prior to call.
   *         Users must approveDelegation debt asset to this contract prior to call.
   *         Users must use reserve as collateral.
   * @param amount Amount to be used as basis for the flashloan.
   * @param multiplier Multiplier for flashloan amount. Determines how much will be borrowed in relation to the user's input.
   * @param data Data from router(1Inch or Uniswap) API.
   */
  function openPosition(uint256 amount, uint256 multiplier, bytes calldata data) external {
    bytes memory params = abi.encode(msg.sender, amount, data, Action.Open);

    POOL.flashLoanSimple(
      address(this), // receiver
      DAI, // flashloan asset
      amount.percentMul(multiplier), // flashloan amount
      params,
      REFERRAL_CODE
    );
  }

  /**
   * @dev Initiates a flashloan leveraging mechanism to close a position.
   * @notice Users must approve this contract for asDAI prior to call.
   * -> send api call to 1inch or uniswap to get the amount of DAI to be flashloaned - debt asset -> DAI
   * -> pass the DAI amount to this amount parameter
   * -> send api call again to 1inch or uniswap to get the calldata for the swap - DAI -> debt asset
   * @param amount Amount to be used as basis for the flashloan.
   * @param data Data from router(1Inch or Uniswap) API.
   */
  function closePosition(uint256 amount, bytes calldata data) external {
    bytes memory params = abi.encode(msg.sender, amount, data, Action.Close);

    POOL.flashLoanSimple(
      address(this), // receiver
      DAI, // flashloan asset
      amount, // flashloan amount
      params,
      REFERRAL_CODE
    );
  }

  /**
   * @dev Handles the logic post receiving the flashloan.
   * @param asset Address of the flashloan asset.
   * @param amount Amount of the flashloan.
   * @param premium Amount to be paid as premium for the flashloan.
   * @param initiator Address initiating the flashloan.
   * @param params Additional data required for processing.
   * @return A boolean indicating if the operation was successful.
   */
  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    // _amount = amount of user input
    (address sender, uint256 _amount, bytes memory data, Action action) = abi.decode(
      params,
      (address, uint256, bytes, Action)
    );
    FlashLoanVars memory vars;

    vars.debtAsset = _debtAsset;
    vars.router = _router; // 1Inch or Uniswap
    vars.aave = POOL; // aave v3
    vars.protocolFee = _protocolFee;

    if (action == Action.Open) {
      // Read storage variables once and keep them in memory
      vars.supplyAmount = _amount + amount; // flashloan amount + amount from sender

      // Step 1: Transfer assets from sender
      IERC20(asset).safeTransferFrom(sender, address(this), _amount);

      // Step 2: Supply dai to sDai vault
      vars.depositAmount = _supplyToSDai(asset, vars.supplyAmount);

      // Step 3: Supply to Aave v3
      _depositToAave(vars.depositAmount, sender, vars.aave);

      // Step 4: Borrow from Aave v3
      vars.borrowAmount = _borrowFromAave(vars.debtAsset, vars.depositAmount, sender, vars.aave);

      // Step 5: Perform Swap debt asset to DAI
      _swap(vars.router, DAI, vars.debtAsset, vars.borrowAmount, sender, data);

      // Step 6: Repay flashloan, charge fees and transfer leftover to sender
      _repayLoanAndFees(amount, premium, sender, vars.protocolFee, address(vars.aave));

      emit OpenPosition(
        sender,
        _amount,
        vars.depositAmount,
        vars.borrowAmount,
        premium,
        vars.protocolFee
      );
    } else {
      // Step 1: Swap DAI to debt asset
      vars.repayAmount = _swap(vars.router, vars.debtAsset, DAI, amount, sender, data);

      // Step 2: Repay debt asset to Aave v3
      _repayToAave(vars.debtAsset, vars.repayAmount, sender, vars.aave);

      // Step 3: Withdraw sDAI from Aave v3
      vars.withdrawnAmount = _withdrawFromAave(sender, vars.aave);

      // Step 4: Withdraw DAI from sDAI vault
      _redeemFromSDai(vars.withdrawnAmount);

      // Step 5: Repay flashloan, charge fees and transfer principal + profit to the sender
      _repayLoanAndFees(amount, premium, sender, vars.protocolFee, address(vars.aave));

      // Step 6: Transfer leftover amount of debt asset to the sender
      IERC20(vars.debtAsset).safeTransfer(sender, IERC20(vars.debtAsset).balanceOf(address(this)));

      emit ClosePosition(sender, vars.withdrawnAmount, vars.repayAmount, premium, vars.protocolFee);
    }

    return true;
  }

  /**
   * @dev Approves the DAI to 1Inch or Uniswap router.
   * @param router Address of the router.
   */
  function approveRouter(address router) external onlyOwner {
    IERC20(_debtAsset).approve(router, type(uint256).max);
  }

  /**
   * @dev Calculates the amount to be borrowed from Aave v3.
   * @param asset The asset to be borrowed.
   * @param amount The origin amount of DAI supplied by the user.
   * @param multiplier Multiplier for flashloan amount. Determines how much will be borrowed in relation to the user's input.
   */
  function getBorrowAmount(
    address asset,
    uint256 amount,
    uint256 multiplier
  ) external view returns (uint256) {
    uint256 flashLoanAmount = amount.percentMul(multiplier);
    // sDAI share that deposited to Aave v3
    uint256 depositAmount = IERC4626(SDAI).previewDeposit(amount + flashLoanAmount);

    return _calcBorrowAmount(asset, depositAmount);
  }

  /**
   * @dev Fetches the debt asset's address.
   * @return Address of the debt asset.
   */
  function DEBT_ASSET() external view returns (address) {
    return _debtAsset;
  }

  /**
   * @dev Fetches the current protocol fee.
   * @return Current protocol fee.
   */
  function PROTOCOL_FEE() external view returns (uint256) {
    return _protocolFee;
  }

  /**
   * @dev Fetches the DEX router's address.
   * @return Address of the DEX router.
   */
  function ROUTER() external view returns (address) {
    return _router;
  }

  /**
   * @dev Fetches the treasury's address.
   * @return Address of the treasury.
   */
  function TREASURY_ADDRESS() external view returns (address) {
    return _treasuryAddress;
  }

  /**
   * @dev Fetches the withdrawal ratio.
   * @return withdrawal ratio.
   */
  function WITHDRAWAL_RATIO() external view returns (uint256) {
    return _withdrawalRatio;
  }

  /**
   * @dev Allows owner to update address of the debt asset.
   * @param debtAsset Address of the new debt asset.
   */
  function setDebtAsset(address debtAsset) external onlyOwner {
    _debtAsset = debtAsset;
  }

  /**
   * @dev Allows owner to set a new protocol fee.
   * @param protocolFee New fee for the protocol.
   */
  function setProtocolFee(uint256 protocolFee) external onlyOwner {
    _protocolFee = protocolFee;
  }

  /**
   * @dev Allows owner to set a new DEX router address.
   * @param router Address of the new DEX router.
   */
  function setRouter(address router) external onlyOwner {
    _router = router;
  }

  /**
   * @dev Allows owner to set a new treasury address.
   * @param treasuryAddress Address of the new treasury.
   */
  function setTreasuryAddress(address treasuryAddress) external onlyOwner {
    _treasuryAddress = treasuryAddress;
  }

  /**
   * @dev Allows owner to set a new withdrawal ratio.
   * @param withdrawalRatio New ratio for withdrawal.
   */
  function setWithdrawalRatio(uint256 withdrawalRatio) external onlyOwner {
    _withdrawalRatio = withdrawalRatio;
  }

  /* ============ Internal Functions ============ */

  /**
   * @dev Supplies assets to a yield-generating protocol. e.g. supply DAI to DSR(sDAI).
   * @notice This function takes the sum of the flash loan amount and the deposit amount to supply to a yield protocol.
   * @param asset The asset that will be supplied to the yield protocol.
   * @param amount The leveraged amount deposited of sDAI by the user.
   * @return The sDAI balance(shares of sDAI vault) to supply to the aave v3
   */
  function _supplyToSDai(address asset, uint256 amount) internal returns (uint256) {
    // approve DAI to sDAI
    if (IERC20(asset).allowance(address(this), SDAI) < amount) {
      IERC20(asset).safeApprove(SDAI, type(uint256).max);
    }

    return IERC4626(SDAI).deposit(amount, address(this));
  }

  /**
   * @dev Redeems sDAI shares for DAI tokens.
   * @notice This function takes the amount of sDAI shares to redeem and returns the amount of DAI tokens withdrawn from the sDAI vault.
   * @param shares The number of sDAI shares to redeem.
   * @return amount The amount of DAI tokens withdrawn from the sDAI vault.
   */
  function _redeemFromSDai(uint256 shares) internal returns (uint256) {
    return IERC4626(SDAI).redeem(shares, address(this), address(this));
  }

  /**
   * @dev Deposit yield-bearing assets to Aave v3. e.g. supply sDAI to Aave v3.
   * @notice This function takes yield-bearing assets and deposits them into Aave v3.
   * @param amount The amount of the yield-bearing asset.
   * @param onBehalfOf The address that will receive the aTokens.
   * @param aave The Aave v3 lending pool.
   */
  function _depositToAave(uint256 amount, address onBehalfOf, IPool aave) internal {
    // approve sDAI to aave v3
    if (IERC20(SDAI).allowance(address(this), address(aave)) < amount) {
      IERC20(SDAI).safeApprove(address(aave), type(uint256).max);
    }

    // deposit sDAI to aave v3 on behalf of sender
    aave.supply(SDAI, amount, onBehalfOf, REFERRAL_CODE);
  }

  /**
   * @dev Borrows an asset from Aave. e.g. borrow debt asset from Aave v3.
   * @notice This function borrows an amount based on the supplied collateral's LTV ratio.
   * @param asset The asset that will be borrowed from Aave v3.
   * @param depositAmount The amount of sDAI deposited to Aave pool.
   * @param onBehalfOf The address that will receive the borrowed amount.
   * @param pool The Aave v3 lending pool.
   * @return The amount borrowed.
   */
  function _borrowFromAave(
    address asset,
    uint256 depositAmount,
    address onBehalfOf,
    IPool pool
  ) internal returns (uint256) {
    uint256 amount = _calcBorrowAmount(asset, depositAmount);

    // borrow debt asset from aave v3 on behalf of sender
    pool.borrow(asset, amount, INTEREST_RATE_MODE, REFERRAL_CODE, onBehalfOf);

    return amount;
  }

  /**
   * @dev Repays a debt to the Aave lending pool.
   * @param asset The asset to repay (e.g., DAI, USDC).
   * @param amount The amount to repay.
   * @param onBehalfOf Address of the account for which the debt will be repaid.
   * @param pool The Aave lending pool.
   */
  function _repayToAave(address asset, uint256 amount, address onBehalfOf, IPool pool) internal {
    // approve debt asset to aave v3
    if (IERC20(asset).allowance(address(this), address(pool)) < amount) {
      IERC20(asset).safeApprove(address(pool), type(uint256).max);
    }
    // calc maximum withdrawable amount
    pool.repay(asset, amount, INTEREST_RATE_MODE, onBehalfOf);
  }

  /**
   * @dev Withdraws aToken (interest-bearing token) from Aave.
   * @notice This function transfers asDAI from the sender to this contract and withdraws the amount of sDAI from Aave v3.
   * @param sender The address that initiated the operation.
   * @param pool The Aave lending pool.
   * @return The amount of sDAI withdrawn.
   */
  function _withdrawFromAave(address sender, IPool pool) internal returns (uint256) {
    address aTokenAddress = pool.getReserveData(SDAI).aTokenAddress;
    uint256 balance = IERC20(aTokenAddress).balanceOf(sender);

    if (_userHasMultipleCollaterals(sender, pool)) {
      balance = balance.percentMul(_withdrawalRatio);
    }
    // Transfer asDAI to address(this)
    IERC20(aTokenAddress).transferFrom(sender, address(this), balance);

    return pool.withdraw(SDAI, balance, address(this));
  }

  /**
   * @dev Swap ERC20_Token using dex or dex aggregator.
   * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
   * @param toToken The address of the token to buy.
   * @param fromToken The address of the token to sell.
   * @param amount The amount of the token to sell.
   * @param sender The address that initiated the operation.
   * @param callData Data from router(1Inch or Uniswap) API.
   */
  function _swap(
    address router,
    address toToken,
    address fromToken,
    uint256 amount,
    address sender,
    bytes memory callData
  ) internal returns (uint256) {
    if (IERC20(fromToken).allowance(address(this), address(router)) < amount) {
      IERC20(fromToken).safeApprove(address(router), type(uint256).max);
    }

    uint256 initalBalalance = IERC20(toToken).balanceOf(address(this));

    (bool success, bytes memory results) = router.call(callData);

    if (!success) {
      revert(string(results));
    }

    uint256 finalBalalance = IERC20(toToken).balanceOf(address(this));
    uint256 buyAmount = finalBalalance - initalBalalance;

    emit Exchange(sender, toToken, fromToken, amount, buyAmount);

    return buyAmount;
  }

  /**
   * @dev Repays the flash loan and handles protocol fees.
   * @notice This function repays the flash loan amount, handles protocol fees, and transfers value(leftover | amount) amount back to the sender.
   * @param amount The amount of the flash loan.
   * @param premium The premium for the flash loan.
   * @param sender The address that initiated the operation.
   * @param protocolFee The protocol fee in basis point.
   * @param aave The Aave v3 lending pool.
   */
  function _repayLoanAndFees(
    uint256 amount,
    uint256 premium,
    address sender,
    uint256 protocolFee,
    address aave
  ) internal {
    uint256 balance = IERC20(DAI).balanceOf(address(this));
    uint256 amountOwing = amount + premium; // flash loan repay amount
    uint256 fee = amount.percentMul(protocolFee);

    require(balance >= amountOwing + fee, "Not enough funds to repay flashloan");

    /**
     * on position open, below remain represents the leftover amount of DAI
     * on position close, below remain + leftover amount of debt asset represents the principal + profit amount after charging fees
     */
    uint256 remain = balance - (amountOwing + fee);

    // transfer protocol fee to treasury
    if (protocolFee > 0) {
      IERC20(DAI).safeTransfer(_treasuryAddress, fee);
    }
    // transfer the remaining amount to sender
    IERC20(DAI).safeTransfer(sender, remain);

    // approve the LendingPool contract allowance to *pull* the owed amount
    IERC20(DAI).safeApprove(aave, amountOwing);
  }

  /**
   * @dev Calculates the amount to be borrowed from Aave v3.
   * @param asset The asset to be borrowed.
   * @param amount The amount of sDAI deposited to Aave pool.
   */
  function _calcBorrowAmount(address asset, uint256 amount) internal view returns (uint256) {
    uint8 decimals = IERC20Metadata(asset).decimals();
    IPoolAddressesProvider addressProvider = ADDRESSES_PROVIDER;
    IPriceOracle oracle = IPriceOracle(addressProvider.getPriceOracle());

    (, uint256 ltv, , , , , , , , ) = IPoolDataProvider(addressProvider.getPoolDataProvider())
      .getReserveConfigurationData(SDAI);

    // prices in eth
    uint256 sDaiPrice = oracle.getAssetPrice(SDAI);
    uint256 assetPrice = oracle.getAssetPrice(asset);
    // borrow amount in eth
    uint256 amountInEth = (amount * sDaiPrice).percentMul(ltv) / assetPrice;

    // round down to avoid aritheic overflow
    return (((amountInEth * (10 ** decimals)) / 1e18 / (10 ** decimals)) * (10 ** decimals));
  }

  /**
   * @dev Checks if the user has multiple collaterals.
   * @param user The address of the user.
   * @param pool The Aave v3 lending pool.
   * @return A boolean indicating if the user has multiple collaterals.
   */
  function _userHasMultipleCollaterals(address user, IPool pool) internal view returns (bool) {
    IPriceOracle oracle = IPriceOracle(ADDRESSES_PROVIDER.getPriceOracle());
    uint256 balance = IERC20(pool.getReserveData(SDAI).aTokenAddress).balanceOf(user);
    uint256 price = oracle.getAssetPrice(SDAI);
    uint256 sDaiAmountInEth = (balance * price) / 1e18;
    (uint256 totalCollateralBase, , , , , ) = pool.getUserAccountData(user);

    return totalCollateralBase > sDaiAmountInEth;
  }
}
