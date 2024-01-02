// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20WithPermit.sol";
import "./GPv2SafeERC20.sol";
import "./IPool.sol";
import "./IAToken.sol";
import "./IBaseTokenWrapper.sol";

/**
 * @title BaseTokenWrapper
 * @author Aave
 * @notice Base contract to enable intermediate wrap/unwrap of a token upon supply/withdraw from a Pool
 */
abstract contract BaseTokenWrapper is Ownable, IBaseTokenWrapper {
  using GPv2SafeERC20 for IERC20;

  /// @inheritdoc IBaseTokenWrapper
  address public immutable TOKEN_IN;

  /// @inheritdoc IBaseTokenWrapper
  address public immutable TOKEN_OUT;

  /// @inheritdoc IBaseTokenWrapper
  IPool public immutable POOL;

  /**
   * @dev Constructor
   * @param tokenIn ERC-20 token that will be wrapped in supply operations
   * @param tokenOut ERC-20 token received upon wrapping
   * @param pool The address of the Aave Pool
   * @param owner The address to transfer ownership to
   */
  constructor(address tokenIn, address tokenOut, address pool, address owner) {
    TOKEN_IN = tokenIn;
    TOKEN_OUT = tokenOut;
    POOL = IPool(pool);
    transferOwnership(owner);
    IERC20(tokenOut).approve(pool, type(uint256).max);
  }

  /// @inheritdoc IBaseTokenWrapper
  function supplyToken(
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external returns (uint256) {
    return _supplyToken(amount, onBehalfOf, referralCode);
  }

  /// @inheritdoc IBaseTokenWrapper
  function supplyTokenWithPermit(
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    PermitSignature calldata signature
  ) external returns (uint256) {
    // explicitly left try-catch block blank to protect users from permit griefing
    try
      IERC20WithPermit(TOKEN_IN).permit(
        msg.sender,
        address(this),
        amount,
        signature.deadline,
        signature.v,
        signature.r,
        signature.s
      )
    {} catch {}
    return _supplyToken(amount, onBehalfOf, referralCode);
  }

  /// @inheritdoc IBaseTokenWrapper
  function withdrawToken(
    uint256 amount,
    address to
  ) external returns (uint256) {
    IAToken aTokenOut = IAToken(POOL.getReserveData(TOKEN_OUT).aTokenAddress);
    return _withdrawToken(amount, to, aTokenOut);
  }

  /// @inheritdoc IBaseTokenWrapper
  function withdrawTokenWithPermit(
    uint256 amount,
    address to,
    PermitSignature calldata signature
  ) external returns (uint256) {
    IAToken aTokenOut = IAToken(POOL.getReserveData(TOKEN_OUT).aTokenAddress);
    // explicitly left try-catch block blank to protect users from permit griefing
    try
      aTokenOut.permit(
        msg.sender,
        address(this),
        amount,
        signature.deadline,
        signature.v,
        signature.r,
        signature.s
      )
    {} catch {}
    return _withdrawToken(amount, to, aTokenOut);
  }

  /// @inheritdoc IBaseTokenWrapper
  function rescueTokens(
    IERC20 token,
    address to,
    uint256 amount
  ) external onlyOwner {
    token.safeTransfer(to, amount);
  }

  /// @inheritdoc IBaseTokenWrapper
  function rescueETH(address to, uint256 amount) external onlyOwner {
    (bool success, ) = to.call{value: amount}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  /// @inheritdoc IBaseTokenWrapper
  function getTokenOutForTokenIn(
    uint256 amount
  ) external view virtual returns (uint256);

  /// @inheritdoc IBaseTokenWrapper
  function getTokenInForTokenOut(
    uint256 amount
  ) external view virtual returns (uint256);

  /**
   * @dev Helper to convert an amount of token to wrapped version and supplies to Pool
   * @param amount The amount of the token to wrap and supply to the Pool
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards
   * @return The final amount supplied to the Pool, post-wrapping
   */
  function _supplyToken(
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) internal returns (uint256) {
    require(amount > 0, 'INSUFFICIENT_AMOUNT_TO_SUPPLY');
    IERC20(TOKEN_IN).safeTransferFrom(msg.sender, address(this), amount);
    uint256 amountWrapped = _wrapTokenIn(amount);
    require(amountWrapped > 0, 'INSUFFICIENT_WRAPPED_TOKEN_RECEIVED');
    POOL.supply(TOKEN_OUT, amountWrapped, onBehalfOf, referralCode);
    return amountWrapped;
  }

  /**
   * @notice Helper to withdraw the wrapped token from the Pool and unwraps it, sending to the recipient
   * @param amount The amount of the token to withdraw from the Pool and unwrap
   * @param to The address that will receive the unwrapped token
   * @param aTokenOut The AToken that will be withdrawn from the Pool
   * @return The final amount withdrawn from the Pool, post-unwrapping
   */
  function _withdrawToken(
    uint256 amount,
    address to,
    IAToken aTokenOut
  ) internal returns (uint256) {
    require(amount > 0, 'INSUFFICIENT_AMOUNT_TO_WITHDRAW');
    uint256 aTokenOutBalance = aTokenOut.balanceOf(msg.sender);
    if (amount == type(uint256).max) {
      amount = aTokenOutBalance;
    }
    require(amount <= aTokenOutBalance, 'INSUFFICIENT_BALANCE_TO_WITHDRAW');
    uint256 aTokenBalanceBefore = aTokenOut.balanceOf(address(this));
    aTokenOut.transferFrom(msg.sender, address(this), amount);
    uint256 aTokenAmountReceived = aTokenOut.balanceOf(address(this)) -
      aTokenBalanceBefore;
    POOL.withdraw(TOKEN_OUT, aTokenAmountReceived, address(this));
    uint256 amountUnwrapped = _unwrapTokenOut(aTokenAmountReceived);
    require(amountUnwrapped > 0, 'INSUFFICIENT_UNWRAPPED_TOKEN_RECEIVED');
    IERC20(TOKEN_IN).safeTransfer(to, amountUnwrapped);
    return amountUnwrapped;
  }

  /**
   * @notice Helper to wrap an amount of tokenIn, receiving tokenOut
   * @param amount The amount of tokenIn to wrap
   * @return The amount of tokenOut received
   */
  function _wrapTokenIn(uint256 amount) internal virtual returns (uint256);

  /**
   * @notice Helper to unwrap an amount of tokenOut, receiving tokenIn
   * @param amount The amount of tokenOut to unwrap
   * @return The amount of tokenIn received
   */
  function _unwrapTokenOut(uint256 amount) internal virtual returns (uint256);
}
