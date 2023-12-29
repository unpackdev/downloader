// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// solhint-disable-next-line no-unused-import
import "./Permit2Transfers.sol";
import "./Token.sol";
import "./ISwapPermit2Adapter.sol";
import "./BasePermit2Adapter.sol";

/**
 * @title Swap Permit2 Adapter
 * @author Sam Bugs
 * @notice This contracts adds Permit2 capabilities to existing token swap contracts by acting as a proxy. It performs
 *         some extra checks to guarantee that the minimum amounts are respected
 * @dev It's important to note that this contract should never hold any funds outside of the scope of a transaction,
 *      nor should it be granted "regular" ERC20 token approvals. This contract is meant to be used as a proxy, so
 *      the only tokens approved/transferred through Permit2 should be entirely spent in the same transaction.
 *      Any unspent allowance or remaining tokens on the contract can be transferred by anyone, so please be careful!
 */
abstract contract SwapPermit2Adapter is BasePermit2Adapter, ISwapPermit2Adapter {
  using Permit2Transfers for IPermit2;
  using Token for address;

  /// @inheritdoc ISwapPermit2Adapter
  function sellOrderSwap(SellOrderSwapParams calldata _params)
    public
    payable
    checkDeadline(_params.deadline)
    returns (uint256 _amountIn, uint256 _amountOut)
  {
    // Take from caller
    PERMIT2.takeFromCaller(_params.tokenIn, _params.amountIn, _params.nonce, _params.deadline, _params.signature);

    // Max approve token in
    _params.tokenIn.maxApproveIfNecessary(_params.allowanceTarget);

    // Execute swap
    uint256 _value = _params.tokenIn == Token.NATIVE_TOKEN ? _params.amountIn : 0;
    _callContract(_params.swapper, _params.swapData, _value);

    // Distribute token out
    _amountOut = _params.tokenOut.distributeTo(_params.transferOut);

    // Check min amount
    if (_amountOut < _params.minAmountOut) revert ReceivedTooLittleTokenOut(_amountOut, _params.minAmountOut);

    // Reset allowance
    _params.tokenIn.setAllowanceIfNecessary(_params.allowanceTarget, 1);

    // Set amount in
    _amountIn = _params.amountIn;
  }

  /// @inheritdoc ISwapPermit2Adapter
  function buyOrderSwap(BuyOrderSwapParams calldata _params)
    public
    payable
    checkDeadline(_params.deadline)
    returns (uint256 _amountIn, uint256 _amountOut)
  {
    // Take from caller
    PERMIT2.takeFromCaller(_params.tokenIn, _params.maxAmountIn, _params.nonce, _params.deadline, _params.signature);

    // Max approve token in
    _params.tokenIn.maxApproveIfNecessary(_params.allowanceTarget);

    // Execute swap
    uint256 _value = _params.tokenIn == Token.NATIVE_TOKEN ? _params.maxAmountIn : 0;
    _callContract(_params.swapper, _params.swapData, _value);

    // Check balance for unspent tokens
    uint256 _unspentTokenIn = _params.tokenIn.balanceOnContract();

    // Distribute token out
    _amountOut = _params.tokenOut.distributeTo(_params.transferOut);

    // Check min amount
    if (_amountOut < _params.amountOut) revert ReceivedTooLittleTokenOut(_amountOut, _params.amountOut);

    // Send unspent to the set recipient
    _params.tokenIn.sendAmountTo(_unspentTokenIn, _params.unspentTokenInRecipient);

    // Reset allowance
    _params.tokenIn.setAllowanceIfNecessary(_params.allowanceTarget, 1);

    // Set amount in
    _amountIn = _params.maxAmountIn - _unspentTokenIn;
  }
}
