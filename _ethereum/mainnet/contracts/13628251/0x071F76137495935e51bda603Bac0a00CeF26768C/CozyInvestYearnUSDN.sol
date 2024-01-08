// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ICozyInvest.sol";
import "./CozyInvestHelpers.sol";

interface ICrvDepositZap {
  function token() external view returns (address);

  function add_liquidity(uint256[4] calldata amounts, uint256 minMintAmount) external payable returns (uint256);

  function remove_liquidity_one_coin(
    uint256 amount,
    int128 index,
    uint256 minAmount
  ) external returns (uint256);
}

interface IYVault is IERC20 {
  function deposit() external returns (uint256); // providing no inputs to `deposit` deposits max amount for msg.sender

  function withdraw(uint256 maxShares) external returns (uint256); // defaults to msg.sender as recipient and 0.01 BPS maxLoss
}

/**
 * @notice On-chain scripts for borrowing from Cozy and using the borrowed funds to supply to Curve, and
 * depositing those Curve receipt tokens into the Yearn USDN vault
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestYearnUSDN is CozyInvestHelpers, ICozyInvest3, ICozyDivest3 {
  using SafeERC20 for IERC20;

  // --- Cozy markets ---
  /// @notice Cozy protection market to borrow from: Cozy-USDC-3-Yearn V2 Curve USDN Trigger
  ICozyToken public constant protectionMarket = ICozyToken(0x11581582Aa816c8293e67c726AF49Fc2C8b98C6e);

  /// @notice Cozy money market with USDC underlying
  ICozyToken public constant moneyMarket = ICozyToken(0xdBDF2fC3Af896e18f2A9DC58883d12484202b57E);

  /// @notice USDC
  IERC20 public immutable underlying;

  // --- Curve parameters ---
  /// @notice Curve Deposit Zap helper contract
  ICrvDepositZap public constant depositZap = ICrvDepositZap(0x094d12e5b541784701FD8d65F11fc0598FBC6332);

  /// @notice Curve USDN receipt token
  IERC20 public immutable curveToken;

  // @dev Index to use in arrays when specifying USDC for the Curve deposit zap
  int128 internal constant usdcIndex = 2;

  // --- Yearn Parameters ---
  /// @notice Yearn USDN vault
  IYVault public constant yearn = IYVault(0x3B96d491f067912D18563d56858Ba7d6EC67a6fa);

  constructor() {
    underlying = IERC20(moneyMarket.underlying());
    curveToken = IERC20(depositZap.token());
  }

  /**
   * @notice Protected invest method for borrowing from given cozy market, using those funds to add
   * liquidity to the Curve pool, and depositing that receipt token into the Yearn vault
   * @param _market Address of the market to borrow from
   * @param _borrowAmount Amount to borrow and deposit into Curve
   * @param _curveMinAmountOut The minAmountOut we expect to receive when adding liquidity to Curve
   */
  function invest(
    address _market,
    uint256 _borrowAmount,
    uint256 _curveMinAmountOut
  ) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // Borrow USDC from Cozy
    require(ICozyToken(_market).borrow(_borrowAmount) == 0, "Borrow failed");

    // Add liquidity to Curve, which returns a receipt token
    underlying.safeApprove(address(depositZap), type(uint256).max);
    depositZap.add_liquidity([0, 0, _borrowAmount, 0], _curveMinAmountOut);

    // Deposit the Curve USDN receipt tokens into the Yearn vault
    curveToken.safeApprove(address(yearn), type(uint256).max);
    yearn.deposit();
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _market Address of the market to repay
   * @param _recipient Address where any leftover tokens should be transferred
   * @param _yearnRedeemAmount Amount of Yearn receipt tokens to redeem
   * @param _curveMinAmountOut The minAmountOut we expect to receive when removing liquidity from Curve
   * @param _excessTokens Quantity to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount obtained from withdrawing from the invest opportunity will not cover the full debt. A value of zero
   * will not attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function divest(
    address _market,
    address _recipient,
    uint256 _yearnRedeemAmount,
    uint256 _curveMinAmountOut,
    uint256 _excessTokens
  ) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // Redeem Yearn receipt tokens for Curve USDN receipt tokens
    uint256 _quantityRedeemed = yearn.withdraw(_yearnRedeemAmount);

    // Approve Curve's depositZap to spend our yearn tokens. We skip the allowance check and just always approve,
    // because it's a negligible impact in gas cost relative to transaction cost, but makes contract deploy cheaper
    curveToken.safeApprove(address(depositZap), type(uint256).max);

    // Redeem from Curve
    depositZap.remove_liquidity_one_coin(_quantityRedeemed, usdcIndex, _curveMinAmountOut);

    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    executeMaxRepay(_market, address(underlying), _excessTokens);

    // Transfer any remaining tokens to the user after paying back borrow
    underlying.transfer(_recipient, underlying.balanceOf(address(this)));
  }
}
