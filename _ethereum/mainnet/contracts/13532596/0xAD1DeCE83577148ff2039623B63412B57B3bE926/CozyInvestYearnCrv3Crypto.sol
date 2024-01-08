// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./Address.sol";
import "./ICozy.sol";
import "./ICozyInvest.sol";

interface ICrvDepositZap {
  function add_liquidity(
    uint256[3] calldata amounts,
    uint256 minMintAmount,
    address receiver
  ) external payable returns (uint256);

  function remove_liquidity_one_coin(
    uint256 amount,
    uint256 index,
    uint256 minAmount,
    address receiver
  ) external returns (uint256);
}

interface IYVault is IERC20 {
  function deposit() external returns (uint256); // providing no inputs to `deposit` deposits max amount for msg.sender

  function withdraw(uint256 maxShares) external returns (uint256); // defaults to msg.sender as recipient and 0.01 BPS maxLoss
}

/**
 * @notice On-chain scripts for borrowing from the Cozy-ETH-3-Yearn Curve 3Crypto Trigger protection market, using
 * that ETH to add liquidity to the Curve 3Crypto USDT/WBTC/WETH pool, then supplying those receipt tokens to the
 * Yearn Curve 3Crypto Pool yVault
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestYearnCrv3Crypto is ICozyInvest1, ICozyDivest1 {
  using Address for address payable;
  using SafeERC20 for IERC20;

  /// @notice Cozy protection market with ETH underlying to borrow from: Cozy-ETH-3-Yearn Curve 3Crypto Trigger
  address public constant protectionMarket = 0x43647239EdE197099B57bf72d0373f8049AcfB0F;

  /// @notice Cozy non-protection market with ETH underlying
  address public constant moneyMarket = 0xF8ec0F87036565d6B2B19780A54996c3B03e91Ea;

  /// @notice Curve 3Crypto Pool yVault
  IYVault public constant yearn = IYVault(0xE537B5cc158EB71037D4125BDD7538421981E6AA);

  /// @notice Curve CryptoSwap Deposit Zap -- helper contract for wrapping ETH before depositing
  ICrvDepositZap public constant depositZap = ICrvDepositZap(0x3993d34e7e99Abf6B6f367309975d1360222D446);

  /// @notice Curve 3Crypto receipt token
  IERC20 public constant curveToken = IERC20(0xc4AD29ba4B3c580e6D59105FFf484999997675Ff);

  /// @notice Maximillion contract for repaying ETH debt
  IMaximillion public constant maximillion = IMaximillion(0xf859A1AD94BcF445A406B892eF0d3082f4174088);

  /// @dev Index of WETH in the curve `coins` mapping
  uint256 internal constant ethIndex = 2;

  /**
   * @notice Protected invest method for borrowing from given cozy ETH market,
   * using that ETH to add liquidity to the Curve 3Crypto pool, and depositing that receipt token into a Yearn vault
   * @param _ethMarket Address of the market to borrow ETH from
   * @param _borrowAmount Amount of ETH to borrow and deposit into Curve
   * @param _curveMinAmountOut The minAmountOut we expect to receive when adding liquidity to Curve
   */
  function invest(
    address _ethMarket,
    uint256 _borrowAmount,
    uint256 _curveMinAmountOut
  ) external payable {
    require((_ethMarket == moneyMarket || _ethMarket == protectionMarket), "Invalid borrow market");
    ICozyEther _market = ICozyEther(_ethMarket);

    // Borrow ETH from Cozy market
    require(_market.borrow(_borrowAmount) == 0, "Borrow failed");

    // Add liquidity to Curve, which returns a receipt token
    depositZap.add_liquidity{value: _borrowAmount}([0, 0, _borrowAmount], _curveMinAmountOut, address(this));

    // Approve the yVault to spend our Curve receipt tokens
    if (curveToken.allowance(address(this), address(yearn)) < _borrowAmount) {
      curveToken.safeApprove(address(yearn), type(uint256).max);
    }

    // Deposit into Yearn
    yearn.deposit();
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _ethMarket Address of the market to repay ETH to
   * @param _recipient Address where any leftover ETH should be transferred
   * @param _yearnRedeemAmount Amount of Yearn receipt tokens to redeem
   * @param _curveMinAmountOut The minAmountOut we expect to receive when removing liquidity from Curve
   */
  function divest(
    address _ethMarket,
    address _recipient,
    uint256 _yearnRedeemAmount,
    uint256 _curveMinAmountOut
  ) external payable {
    require((_ethMarket == moneyMarket || _ethMarket == protectionMarket), "Invalid borrow market");

    ICozyEther _market = ICozyEther(_ethMarket);

    // Withdraw from Yearn
    uint256 _quantityRedeemed = yearn.withdraw(_yearnRedeemAmount);

    // Approve Curve's depositZap to spend our receipt tokens
    if (curveToken.allowance(address(this), address(depositZap)) < _yearnRedeemAmount) {
      curveToken.safeApprove(address(depositZap), type(uint256).max);
    }

    // Withdraw from Curve
    depositZap.remove_liquidity_one_coin(_quantityRedeemed, ethIndex, _curveMinAmountOut, address(this));

    // Pay back as much of the borrow as possible, excess ETH is refunded to `recipient`
    maximillion.repayBehalfExplicit{value: address(this).balance}(address(this), _market);

    // Transfer any remaining funds to the user
    payable(_recipient).sendValue(address(this).balance);
  }
}
