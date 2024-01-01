// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IStargate.sol";
import "./LibStarVault.sol";
import "./LibWarp.sol";
import "./IAllowanceTransfer.sol";
import "./IStargateRouter.sol";
import "./IStargateComposer.sol";
import "./PermitParams.sol";

contract Stargate is IStargate {
  using SafeERC20 for IERC20;

  function stargateJumpToken(
    JumpTokenParams calldata params,
    PermitParams calldata permit
  ) external payable {
    LibWarp.state().permit2.permit(
      msg.sender,
      IAllowanceTransfer.PermitSingle(
        IAllowanceTransfer.PermitDetails({
          token: params.token,
          amount: params.amountIn,
          expiration: params.deadline,
          nonce: uint48(permit.nonce)
        }),
        address(this),
        params.deadline
      ),
      permit.signature
    );

    // Transfer tokens from the sender to this contract
    LibWarp.state().permit2.transferFrom(
      msg.sender,
      address(this),
      uint160(params.amountIn),
      params.token
    );

    // NOTE: It is not possible to know how many tokens will be delivered. Therfore positive slippage
    // is never charged
    uint256 amountIn = LibStarVault.calculateAndRegisterFee(
      params.partner,
      params.token,
      params.feeBps,
      params.amountIn,
      params.amountIn
    );

    // NOTE: This lookup is spending 319 gas
    IStargateRouter stargateRouter = IStargateRouter(
      LibWarp.state().stargateComposer.stargateRouter()
    );

    IERC20(params.token).forceApprove(address(stargateRouter), amountIn);

    unchecked {
      stargateRouter.swap{value: msg.value}({
        _dstChainId: params.dstChainId,
        _srcPoolId: params.srcPoolId,
        _dstPoolId: params.dstPoolId,
        //  NOTE: There is no guarantee that `msg.sender` can handle receiving tokens
        _refundAddress: payable(msg.sender),
        _amountLD: amountIn,
        // Apply slippage to the amountOutExpected after fees
        _minAmountLD: params.amountOutExpected > (params.amountIn - amountIn)
          ? LibWarp.applySlippage(
            params.amountOutExpected - (params.amountIn - amountIn),
            params.slippageBps
          )
          : 0,
        _lzTxParams: IStargateRouter.lzTxObj({
          dstGasForCall: 0,
          dstNativeAmount: 0,
          dstNativeAddr: ''
        }),
        _to: abi.encodePacked(params.recipient),
        _payload: ''
      });
    }
  }

  function stargateJumpNative(JumpNativeParams calldata params) external payable {
    if (msg.value < params.amountIn) {
      revert InsufficientEthValue();
    }

    // NOTE: It is not possible to know how many tokens will be delivered. Therfore positive slippage
    // is never charged
    uint256 amountIn = LibStarVault.calculateAndRegisterFee(
      params.partner,
      address(0),
      params.feeBps,
      params.amountIn,
      params.amountIn
    );

    unchecked {
      LibWarp.state().stargateComposer.swap{value: msg.value - (params.amountIn - amountIn)}({
        _dstChainId: params.dstChainId,
        _srcPoolId: params.srcPoolId,
        _dstPoolId: params.dstPoolId,
        _refundAddress: payable(msg.sender),
        _amountLD: amountIn,
        // Apply slippage to the amountOutExpected after fees
        _minAmountLD: params.amountOutExpected > params.amountIn - amountIn
          ? LibWarp.applySlippage(
            params.amountOutExpected - (params.amountIn - amountIn),
            params.slippageBps
          )
          : 0,
        _lzTxParams: IStargateRouter.lzTxObj({
          dstGasForCall: 0,
          dstNativeAmount: 0,
          dstNativeAddr: ''
        }),
        _to: abi.encodePacked(params.recipient),
        _payload: ''
      });
    }
  }
}
