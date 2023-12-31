//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./console.sol";

//i mport "./libraries/BytesLib.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
//import "./SafeMath.sol";
import "./IUniswapV2Callee.sol";
import "./IUniswapV3SwapCallback.sol";
import "./IUniswapV3Pool.sol";
//import "./IERC20.sol";
//import "./IERC20.sol";
//import "./IERC2612.sol";
//import "./AnyswapV4CallProxy.sol";

//import "./TickMath.sol";
import "./TickMath_0.8.sol";

import "./IUniswapV3SwapCallback.sol";
import "./IWETH9.sol";
import "./TransferHelper.sol";

//import "./IVault.sol";
//import "./IBasePool.sol";
//import "./IAsset.sol";

import "./CalldataLoader.sol";
//import "./ETHRouter_V4_types.sol";
import "./ETHRouter_V5_types.sol";

import "./addrs_and_selectors.sol";

contract ETHRouter_V5_FromInput is IUniswapV3SwapCallback {
//  using SafeMath for uint;
//  using SafeMath for int;
  using CalldataLoader for uint;
//  using BytesLoader for uint;

  using V5CallType_basic_lib for V5CallType_basic_lib.CallType_basic_vars;
//  using V5CallType_1_lib for V5CallType_1_lib.CallType_1_vars;
  using V5CallType_5_lib for V5CallType_5_lib.CallType_5_vars;
  using V5CallType_6_lib for V5CallType_6_lib.CallType_6_vars;
  using V5CallType_7_lib for V5CallType_7_lib.CallType_7_vars;
  using V5ExecHeader for V5ExecHeader.Header;
//  address current_pool;

  address public owner;
  address public current_caller;
  address private callback_to_check;
  uint public value_to_pay;
  uint public constant network = 1;

  uint public constant SLIPPAGE_LIMIT = 200;

  constructor() {
    owner = msg.sender;
  }

  modifier ownerOnly {
    require(owner == msg.sender, 'ownerOnly');
    _;
  }

  modifier isLocked {
    require(current_caller != address(0), 'isLocked: false');
    _;
  }

  modifier isUnlocked {
    require(current_caller == address(0), 'isUnlocked: false');
    _;
  }

  modifier isCallbackChecked {
    require(callback_to_check == msg.sender, 'callback_to_check failure');
    _;
  }

  function setOwner(address newOwner) external ownerOnly {
    owner = newOwner;
  }


  function exec(bytes calldata data) isUnlocked() external payable returns (uint ind) {
    current_caller = msg.sender;
    (V5ExecHeader.Header memory h, uint ind_) = V5ExecHeader.load(data);
    uint tmp;
    assembly {
      tmp := data.offset
    }
//    uint old_balance = IERC20(uint(h.targetArrInd).loadTokenFromArrayV4(h.tokensOffset + tmp)).balanceOf(msg.sender);
    if (h.fromInput) {
      ind = execFromInputExternalHandler(h, ind_, data);
    } else {
//      ind = execFromOutputExternalHandler(h, ind_, data);
      revert("execFromOutput is not implemented");
    }
//    uint new_balance = IERC20(uint(h.targetArrInd).loadTokenFromArrayV4(h.tokensOffset + tmp)).balanceOf(msg.sender);
//    console.log("balance diff: ", new_balance - old_balance);
    current_caller = address(0);
  }

  function execFromInputExternalHandler(V5ExecHeader.Header memory h, uint ind_, bytes calldata data) internal returns (uint ind) {
    V5ExecState.V5ExecState memory st = h.newState();
    ind = ind_;

    {
      uint tmp;
      assembly {
        tmp := data.offset
      }
      if (st.header.doAcquireInputERC20Token) {
        if (uint256(st.header.sourceArrInd).loadTokenFromArrayV4(st.header.tokensOffset + tmp) == Addrs.WETH9) {
          if (st.msgValueLeft > 0) {
            WETH9(Addrs.WETH9).deposit{value: st.msgValueLeft}();
            st.balances[st.header.sourceArrInd] += st.msgValueLeft;
            st.msgValueLeft = 0;
          }
        } else {
          revert('doAcquireInputERC20Token: only WETH9 tokens are supported');
        }
      }
    }

    while (st.callCounter < st.header.numOfCalls) {
      uint calltype = ind.loadUint8();
      ind++;
////      console.log("i: ", st.callCounter, " | calltype: ", calltype);
      if (calltype == 1) { // transfer to univ2-like pair and swap
        V5CallType_basic_lib.CallType_basic_vars memory basic_vars;
        {
          uint tmp;
          assembly {
            tmp := data.offset
          }
          ind = basic_vars.load(ind, st.header.tokensOffset + tmp, st.header.tokensNum);
        }

        V5CallType_1_extra_lib.do_1_FromInput(basic_vars, st);
      } else if (calltype == 5) { // univ3
        V5CallType_5_lib.CallType_5_vars memory vars;
        {
          uint tmp;
          assembly {
            tmp := data.offset
          }
          ind = vars.load(ind, st.header.tokensOffset + tmp, st.header.tokensNum);
        }
        vars.prepare(st);
        callback_to_check = vars.univ3_pool;
        vars.doItFromInput(st, data);
        callback_to_check = address(0x0);
        vars.afterFromInput(st);
      } else if (calltype == 6) { // balancer
        V5CallType_6_lib.CallType_6_vars memory vars;
        {
          uint tmp;
          assembly {
            tmp := data.offset
          }
          ind = vars.load(ind, st.header.tokensOffset + tmp, st.header.tokensNum);
        }
        vars.prepare(st);
        vars.doItFromInput(st);
//        vars.afterFromInput(st);
      } else if (calltype == 7) { // curve
        V5CallType_7_lib.CallType_7_vars memory vars;
        {
          uint tmp;
          assembly {
            tmp := data.offset
          }
          ind = vars.load(ind, st.header.tokensOffset + tmp, st.header.tokensNum);
        }
        vars.prepare(st);
        vars.doItFromInput(st);
//        vars.afterFromInput(st);
      } else {
        revert("CT");
      }
      st.callCounter++;
    }

//    console.log('st.totals[st.header.targetArrInd]:', st.totals[st.header.targetArrInd]);
//    console.log('treshold:', st.expected[st.header.targetArrInd] * (SLIPPAGE_LIMIT - st.header.slippage)/SLIPPAGE_LIMIT);
    require(st.totals[st.header.targetArrInd] > st.expected[st.header.targetArrInd] * (SLIPPAGE_LIMIT - st.header.slippage)/SLIPPAGE_LIMIT, "slippage is above the threshold");
    uint tmp;
    assembly {
      tmp := data.offset
    }
    if (uint256(st.header.targetArrInd).loadTokenFromArrayV4(st.header.tokensOffset + tmp) == Addrs.WETH9) {
      if (st.header.getNativeETH) {
        if (st.ethAmountToUnwrap > 0) {
//          console.log('WETH9.balanceOf:', IERC20(Addrs.WETH9).balanceOf(address(this)));
//          console.log('st.ethAmountToUnwrap:', st.ethAmountToUnwrap);
          WETH9(Addrs.WETH9).withdraw(st.ethAmountToUnwrap);
        }
        payable(msg.sender).call{value: (st.ethAmountToUnwrap + st.balances[st.header.targetArrInd])}("");
      } else {
        TransferHelper.safeTransfer(Addrs.WETH9, msg.sender, st.balances[st.header.targetArrInd]);
      }
    } else {
      if (st.balances[st.header.targetArrInd] != 0) {
        TransferHelper.safeTransfer(uint256(st.header.targetArrInd).loadTokenFromArrayV4(st.header.tokensOffset + tmp), msg.sender, st.balances[st.header.targetArrInd]);
      }
    }
  }

  struct UniswapV3SwapCallbackData {
    address tokenIn;
    address tokenOut;
    uint amountIn;
    uint amountOut;
//    address payer;
  }

  function uniswapV3SwapCallback(
      int256 amount0Delta,
      int256 amount1Delta,
      bytes calldata _data
  ) external isLocked() isCallbackChecked() override {
      require(amount0Delta > 0 || amount1Delta > 0, 'zero amounts'); // swaps entirely within 0-liquidity regions are not supported

//    console.log("amount0Delta:");
//    console.logInt(amount0Delta);
//    console.log("amount1Delta");
//    console.logInt(amount1Delta);
//    (V5ExecState.V5ExecState memory st, V5CallType_5_lib.CallType_5_vars memory vars, bytes memory data) = abi.decode(_data, (V5ExecState.V5ExecState, V5CallType_5_lib.CallType_5_vars, bytes));
//    console.log("CT_5: st.callCounter:", st.callCounter);

    (address tokenIn, address tokenOut, bool isNative, bool fromSender) = abi.decode(_data, (address, address, bool, bool));
    (uint amountIn, uint amountOut) = tokenIn < tokenOut ? (
      uint256(amount0Delta),
      uint256(-amount1Delta)
    ) : (
      uint256(amount1Delta),
      uint256(-amount0Delta)
    );

//    V5Utils.pay(tokenIn, fromSender ? current_caller : address(this), msg.sender, amountIn);
    if (fromSender) {
      TransferHelper.safeTransferFrom(tokenIn, current_caller, msg.sender, amountIn);
    } else {
      if (isNative) {
        WETH9(Addrs.WETH9).deposit{value: amountIn}();
      }
      TransferHelper.safeTransfer(tokenIn, msg.sender, amountIn);
    }
  }

  fallback() external payable {
//    console.log('get paid');
  }
}
