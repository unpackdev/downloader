// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IStateless.sol";
import "./IEnergyShield.sol";
import "./LibStarVault.sol";
import "./LibWarp.sol";
import "./IAllowanceTransfer.sol";
import "./PermitParams.sol";

contract Stateless is IStateless {
  using SafeERC20 for IERC20;

  function energyShieldAddress() external view returns (address) {
    return address(LibWarp.state().energyShield);
  }

  /**
   * NOTE: The tokens must already be moved to the energyShield/target
   */
  function warpStatelessSingleInternal(
    SingleParams calldata params
  ) internal returns (uint256 amountOut) {
    amountOut = LibWarp.state().energyShield.single{value: msg.value}(
      IEnergyShield.SingleParams({
        tokenOut: params.tokenOut,
        target: params.target,
        data: params.data,
        delivers: params.delivers
      })
    );

    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      params.tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    if (params.tokenOut == address(0)) {
      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);
    }

    emit LibWarp.Warp(params.partner, params.tokenIn, params.tokenOut, params.amountIn, amountOut);
  }

  function warpStatelessSinglePermit(
    SingleParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut) {
    // Permit tokens/set allowance
    LibWarp.state().permit2.permit(
      msg.sender,
      IAllowanceTransfer.PermitSingle({
        details: IAllowanceTransfer.PermitDetails({
          token: params.tokenIn,
          amount: uint160(params.amountIn),
          expiration: uint48(params.deadline),
          nonce: uint48(permit.nonce)
        }),
        spender: address(this),
        sigDeadline: uint256(params.deadline)
      }),
      permit.signature
    );

    // Transfer tokens to energy shield or target depending on `params.push`
    LibWarp.state().permit2.transferFrom(
      msg.sender,
      params.push ? params.target : address(LibWarp.state().energyShield),
      uint160(params.amountIn),
      params.tokenIn
    );

    return warpStatelessSingleInternal(params);
  }

  function warpStatelessSingle(
    SingleParams calldata params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    if (params.tokenIn == address(0)) {
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }
    } else {
      IERC20(params.tokenIn).safeTransferFrom(
        msg.sender,
        params.push ? params.target : address(LibWarp.state().energyShield),
        params.amountIn
      );
    }

    return warpStatelessSingleInternal(params);
  }

  /**
   * NOTE: The tokens must already be moved to the energy shield/target
   */
  function warpStatelessMultiInternal(
    MultiParams calldata params
  ) internal returns (uint256 amountOut) {
    amountOut = LibWarp.state().energyShield.multi{value: msg.value}(
      IEnergyShield.MultiParams({
        tokenOut: params.tokenOut,
        targets: params.targets,
        data: params.data,
        offsets: params.offsets,
        delivers: params.delivers
      })
    );

    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      params.tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    if (params.tokenOut == address(0)) {
      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);
    }

    emit LibWarp.Warp(params.partner, params.tokenIn, params.tokenOut, params.amountIn, amountOut);
  }

  function warpStatelessMultiPermit(
    MultiParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut) {
    // Permit tokens/set allowance
    LibWarp.state().permit2.permit(
      msg.sender,
      IAllowanceTransfer.PermitSingle({
        details: IAllowanceTransfer.PermitDetails({
          token: params.tokenIn,
          amount: uint160(params.amountIn),
          expiration: uint48(params.deadline),
          nonce: uint48(permit.nonce)
        }),
        spender: address(this),
        sigDeadline: uint256(params.deadline)
      }),
      permit.signature
    );

    // Transfer tokens to energy shield or the first target depending on `params.push`
    LibWarp.state().permit2.transferFrom(
      msg.sender,
      params.push ? params.targets[0] : address(LibWarp.state().energyShield),
      uint160(params.amountIn),
      params.tokenIn
    );

    return warpStatelessMultiInternal(params);
  }

  function warpStatelessMulti(
    MultiParams calldata params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    if (params.tokenIn == address(0)) {
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }
    } else {
      IERC20(params.tokenIn).safeTransferFrom(
        msg.sender,
        params.push ? params.targets[0] : address(LibWarp.state().energyShield),
        params.amountIn
      );
    }

    return warpStatelessMultiInternal(params);
  }
}
