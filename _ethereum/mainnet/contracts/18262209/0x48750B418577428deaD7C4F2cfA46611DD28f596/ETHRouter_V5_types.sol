//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./console.sol";

//import "./BytesLib.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
//import "./SafeMath.sol";
import "./IUniswapV2Callee.sol";
import "./IUniswapV3SwapCallback.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
//import "./IERC20.sol";
//import "./IERC20.sol";
//import "./IERC2612.sol";
//import "./AnyswapV5CallProxy.sol";

//import "./TickMath.sol";
import "./TickMath_0.8.sol";

import "./IUniswapV3SwapCallback.sol";
import "./IWETH9.sol";

import "./TransferHelper.sol";

import "./IVault.sol";

import "./CalldataLoader.sol";
import "./ETHRouter_V5_types.sol";

import "./addrs_and_selectors.sol";

library V5CallType_basic_lib {
  using CalldataLoader for uint;
  
  struct CallType_basic_vars {
    uint flags;
    uint token_source_ind;
    uint token_target_ind;
    address token_source;
    address token_target;
    uint amount_in_expected;
    uint amount_out_expected;
    uint amount_to_be_sent;
    uint amount_out;
  }

  using V5CallType_basic_lib for CallType_basic_vars;

  uint internal constant CT_BASIC_FROM_SENDER = 1;
  uint internal constant CT_BASIC_TO_SENDER = 2;

  function load(CallType_basic_vars memory self, uint ind, uint tokens_start_ind, uint tokens_num) internal pure returns(uint new_ind) {
    self.flags = ind.loadUint8();
    ind++;
////        console.log("self.flags:", self.flags);

    self.token_source_ind = ind.loadUint8();// = uint8(data[ind]);
    ind++;
////        console.log("self.token_source_ind:", self.token_source_ind);
    require(self.token_source_ind < tokens_num, "1LSI");
    self.token_source = self.token_source_ind.loadTokenFromArrayV4(tokens_start_ind);
////        console.log("self.token_source:", self.token_source);

    self.token_target_ind = ind.loadUint8(); //= uint8(data[ind]);
    ind++;
////        console.log("self.token_target_ind:", self.token_target_ind);
    require(self.token_target_ind < tokens_num, "1LTI");
    self.token_target = self.token_target_ind.loadTokenFromArrayV4(tokens_start_ind);
////        console.log("self.token_target:", self.token_target);

    {
      uint amount_in_len = ind.loadUint8();// = uint(uint8(data[ind]));
      ind++;
      self.amount_in_expected = ind.loadVariableUint(amount_in_len);
      ind += amount_in_len;
////          console.log("self.amount_in_expected:", self.amount_in_expected);
    }

    {
      uint amount_out_len = ind.loadUint8();
      ind++;
      self.amount_out_expected = ind.loadVariableUint(amount_out_len);
      ind += amount_out_len;
////          console.log("self.amount_out_expected:", self.amount_out_expected);
    }

    return ind;
  }
}

library V5CallType_1_extra_lib {
  using CalldataLoader for uint;

  uint internal constant CT_1_UNISWAP_OR_SUSHISWAP = 4; // false == uniswap, true == sushiswap
  uint internal constant CT_1_SUSHISWAP = 4;

  function do_1_FromInput(V5CallType_basic_lib.CallType_basic_vars memory self, V5ExecState.V5ExecState memory st) internal {
    if (self.token_source_ind == st.header.sourceArrInd) {
      self.amount_to_be_sent = self.amount_in_expected;
    } else {
      self.amount_to_be_sent = ((self.amount_in_expected * st.totals[self.token_source_ind]) / st.expected[self.token_source_ind]);
    }

    address v2pair;
    {
      address factory = (self.flags & CT_1_SUSHISWAP) > 0 ? Addrs.SUSHI_FACTORY : Addrs.UNISWAP_V2_FACTORY ;
      (address t0, address t1) = self.token_source < self.token_target ? (self.token_source, self.token_target) : (self.token_target, self.token_source) ;
      v2pair =  IUniswapV2Factory(factory).getPair(t0, t1);
    }
    (uint112 reserve_0, uint112 reserve_1, ) = IUniswapV2Pair(v2pair).getReserves();
    uint amount_out = self.token_source < self.token_target ?
      calcUniswapV2Out(reserve_0, reserve_1, self.amount_to_be_sent) :
      calcUniswapV2Out(reserve_1, reserve_0, self.amount_to_be_sent) ;
    if (amount_out == 0) {
      return;
    }

    if (self.token_source_ind == st.header.sourceArrInd) {
      if (st.header.doAcquireInputERC20Token) {
        TransferHelper.safeTransfer(self.token_source, v2pair, self.amount_to_be_sent);
        st.balances[self.token_source_ind] -= self.amount_to_be_sent;
      } else {
        if (self.token_source == Addrs.WETH9) {
          if (st.msgValueLeft >= self.amount_to_be_sent) {
            WETH9(Addrs.WETH9).deposit{value: self.amount_to_be_sent}();
            TransferHelper.safeTransfer(self.token_source, v2pair, self.amount_to_be_sent);
            st.msgValueLeft -= self.amount_to_be_sent;
          } else {
            revert('CT1: msg.value insufficient');
          }
        } else {
          TransferHelper.safeTransferFrom(self.token_source, msg.sender, v2pair, self.amount_to_be_sent);
        }
      }
    } else {
      TransferHelper.safeTransfer(self.token_source, v2pair, self.amount_to_be_sent);
      st.balances[self.token_source_ind] -= self.amount_to_be_sent;
    }

//    V5Utils.pay(self.token_source, (self.token_source_ind != st.header.sourceArrInd || (self.token_source == Addrs.WETH9 && msg.value != 0) || st.header.doPrefetchInputToken) ? address(this) : msg.sender, v2pair, self.amount_to_be_sent);

    (uint256 a0, uint256 a1) = (self.token_source < self.token_target) ?
      (uint256(0), amount_out) :
      (amount_out, uint256(0)) ;

    IUniswapV2Pair(v2pair).swap(a0, a1, (self.token_target_ind != st.header.targetArrInd || (self.token_target == Addrs.WETH9 && st.header.getNativeETH)) ? address(this): msg.sender, new bytes(0));

//    if (self.token_source_ind == st.header.sourceArrInd) {
//      if (self.token_source == Addrs.WETH9 && msg.value != 0 || st.header.doAcquireInputERC20Token) {
//        st.balances[self.token_source_ind] -= self.amount_to_be_sent;
//      }
//    } else {
//      st.balances[self.token_source_ind] -= self.amount_to_be_sent;
//    }
    if (self.token_target_ind == st.header.targetArrInd) {
      if (self.token_target == Addrs.WETH9 && st.header.getNativeETH) {
        st.ethAmountToUnwrap += amount_out;
      }
    } else {
      st.balances[self.token_target_ind] += amount_out;
    }
//    if (self.token_target_ind == st.header.targetArrInd && self.token_target == Addrs.WETH9 && st.header.getNativeEth) {
//      st.ethAmountToUnwrap += amount_out;
//    }
    st.totals[self.token_target_ind] += amount_out;
    st.expected[self.token_target_ind] += self.amount_out_expected;
  }

  function calcUniswapV2Out(uint r0, uint r1, uint a0) pure private returns (uint a1) {
    uint numer = r1 * a0 * 997;
    uint denom = r0 * 1000 + a0 * 997;
    a1 = numer / denom; // to round down
  }
}

library V5CallType_6_lib {
  using CalldataLoader for uint;
//  using BytesLoader for uint;

  struct CallType_6_vars {
    uint flags;
    uint token_source_ind;
    uint token_target_ind;
    address token_source;
    address token_target;
    uint amount_in_expected;
    uint amount_out_expected;
    bytes32 balancer_pool_id;
    uint amount_to_be_sent;
    uint amount_out;

    bool isNative;
  }

  using V5CallType_6_lib for CallType_6_vars;

  uint internal constant CT_6_FROM_SENDER = 1;
  uint internal constant CT_6_TO_SENDER = 2;

  function load(CallType_6_vars memory self, uint ind, uint tokens_start_ind, uint tokens_num) internal pure returns (uint new_ind) {
    self.flags = ind.loadUint8();
    ind++;
////        console.log("self.flags:", self.flags);

    self.token_source_ind = ind.loadUint8();// = uint8(data[ind]);
    ind++;
////        console.log("self.token_source_ind:", self.token_source_ind);
    require(self.token_source_ind < tokens_num, "1LSI");
    self.token_source = self.token_source_ind.loadTokenFromArrayV4(tokens_start_ind);
////        console.log("self.token_source:", self.token_source);

    self.token_target_ind = ind.loadUint8(); //= uint8(data[ind]);
    ind++;
////        console.log("self.token_target_ind:", self.token_target_ind);
    require(self.token_target_ind < tokens_num, "1LTI");
    self.token_target = self.token_target_ind.loadTokenFromArrayV4(tokens_start_ind);
////        console.log("self.token_target:", self.token_target);

    {
      uint amount_in_len = ind.loadUint8();// = uint(uint8(data[ind]));
      ind++;
      self.amount_in_expected = ind.loadVariableUint(amount_in_len);
      ind += amount_in_len;
////          console.log("self.amount_in_expected:", self.amount_in_expected);
    }

    {
      uint amount_out_len = ind.loadUint8();
      ind++;
      self.amount_out_expected = ind.loadVariableUint(amount_out_len);
      ind += amount_out_len;
////          console.log("self.amount_out_expected:", self.amount_out_expected);
    }

    self.balancer_pool_id = bytes32(ind.loadUint256());
    ind += 32;

//    console.log('pool_id:');
//    console.logBytes32(self.balancer_pool_id);

    return ind;
  }

  function prepare(CallType_6_vars memory self, V5ExecState.V5ExecState memory st) internal {
    if (self.token_source_ind == st.header.sourceArrInd) {
      self.amount_to_be_sent = self.amount_in_expected;
      if (st.header.doAcquireInputERC20Token) {
        TransferHelper.safeApprove(self.token_source, Addrs.BALANCER_VAULT, self.amount_to_be_sent);
        st.balances[self.token_source_ind] -= self.amount_to_be_sent;
        self.isNative = false;
      } else {
        if (self.token_source == Addrs.WETH9) {
          if (st.msgValueLeft >= self.amount_to_be_sent) {
            self.isNative = true;
            st.msgValueLeft -= self.amount_to_be_sent;
          } else {
            revert('CT6: msg.value insufficient');
          }
        } else {
          TransferHelper.safeTransferFrom(self.token_source, msg.sender, address(this), self.amount_to_be_sent);
          TransferHelper.safeApprove(self.token_source, Addrs.BALANCER_VAULT, self.amount_to_be_sent);
          self.isNative = false;
        }
      }
    } else {
      self.amount_to_be_sent = (self.amount_in_expected * st.totals[self.token_source_ind]) / st.expected[self.token_source_ind];
      TransferHelper.safeApprove(self.token_source, Addrs.BALANCER_VAULT, self.amount_to_be_sent);
      self.isNative = false;
      st.balances[self.token_source_ind] -= self.amount_to_be_sent;
    }
  }

  function doItFromInput(CallType_6_vars memory self, V5ExecState.V5ExecState memory st) internal {
//    console.log('pool_id:');
//    console.logBytes32(self.balancer_pool_id);
//    console.log('self.amount_to_be_sent:', self.amount_to_be_sent);
    (IAsset assetOut, address payable recipient) = self.token_target_ind == st.header.targetArrInd ? 
      (self.token_target == Addrs.WETH9 && st.header.getNativeETH ?
        ((self.flags & CT_6_TO_SENDER > 0) ?  (IAsset(address(0x0)), payable(msg.sender)) : (IAsset(self.token_target), payable(address(this)))) :
        (IAsset(self.token_target), payable(msg.sender))
      ) :
      (IAsset(self.token_target), payable(address(this)))
      ;
    uint256 output = IVault(Addrs.BALANCER_VAULT).swap{value: self.isNative ? self.amount_to_be_sent : 0}(IVault.SingleSwap({
      poolId: self.balancer_pool_id, //bytes32 poolId;
      kind: IVault.SwapKind.GIVEN_IN, //SwapKind kind;
//      assetIn: IAsset(self.token_source == Addrs.WETH9 ? address(0x0) : self.token_source), //IAsset assetIn;
      assetIn: IAsset(self.isNative ? address(0x0) : self.token_source), //IAsset assetIn;
//      assetOut: IAsset(self.token_target == Addrs.WETH9 ? address(0x0) : self.token_target), //IAsset assetOut;
      assetOut: assetOut, //IAsset(self.token_target), //IAsset assetOut;
      amount: self.amount_to_be_sent,//uint256 amount;
      userData: new bytes(0) //bytes userData;
    }),
    IVault.FundManagement({
      sender: address(this), //address sender;
      fromInternalBalance: false, // bool fromInternalBalance;
      recipient: recipient, // self.token_target == Addrs.WETH9 && st.header.getNativeETH ? self.flags & CT_6_TO_SENDER > 0 ? payable(msg.sender) : payable(address(this)), //address payable recipient;
      toInternalBalance: false //bool toInternalBalance;
    }),
      0,
      block.timestamp + 1000
    );
//    if (self.token_source_ind != st.header.sourceArrInd || (self.token_source == Addrs.WETH9 && (msg.value != 0 || st.header.doPrefetchInputToken))) {
//      st.balances[self.token_source_ind] -= self.amount_to_be_sent;
//    }
    if (self.token_target_ind == st.header.targetArrInd) {
//      st.totalOutput += output;
      if (self.token_target == Addrs.WETH9 && st.header.getNativeETH && self.flags & CT_6_TO_SENDER == 0) { // !!!!! FLAG VAR for flexability
        st.ethAmountToUnwrap += output;
      } else {
        // skip
      }
    } else {
      st.balances[self.token_target_ind] += output;
    }
    st.totals[self.token_target_ind] += output;
    st.expected[self.token_target_ind] += self.amount_out_expected;
    self.amount_out = output;
  }

//  function afterFromInput(CallType_6_vars memory self, V5ExecState.V5ExecState memory st) internal {
////    if (self.flags & CT_6_TO_SENDER > 0) {
////      TransferHelper.safeTransfer(self.token_target, msg.sender, self.amount_out);
//////      st.totalTo += uint128(self.amount_out);
////    }
//  }
}

library V5CallType_7_lib {
//  using SafeMath for uint;
  using CalldataLoader for uint;
//  using BytesLoader for uint;

  struct CallType_7_vars {
    uint flags;
    uint token_source_ind;
    uint token_target_ind;
    address token_source;
    address token_target;
    uint amount_in_expected;
    uint amount_out_expected;
    address curve_pool;
    uint curve_pool_source_ind;
    uint curve_pool_target_ind;
    uint amount_to_be_sent;
    uint amount_out;

    bool isNative;
  }

  using V5CallType_7_lib for CallType_7_vars;

  uint internal constant CT_7_FROM_SENDER = 1;
  uint internal constant CT_7_TO_SENDER = 2;

  function load(CallType_7_vars memory self, uint ind, uint tokens_start_ind, uint tokens_num) internal pure returns (uint new_ind) {
    self.flags = ind.loadUint8();
    ind++;
////        console.log("self.flags:", self.flags);

    self.token_source_ind = ind.loadUint8();// = uint8(data[ind]);
    ind++;
////        console.log("self.token_source_ind:", self.token_source_ind);
    require(self.token_source_ind < tokens_num, "1LSI");
    self.token_source = self.token_source_ind.loadTokenFromArrayV4(tokens_start_ind);
////        console.log("self.token_source:", self.token_source);

    self.token_target_ind = ind.loadUint8(); //= uint8(data[ind]);
    ind++;
////        console.log("self.token_target_ind:", self.token_target_ind);
    require(self.token_target_ind < tokens_num, "1LTI");
    self.token_target = self.token_target_ind.loadTokenFromArrayV4(tokens_start_ind);
////        console.log("self.token_target:", self.token_target);

    {
      uint amount_in_len = ind.loadUint8();// = uint(uint8(data[ind]));
      ind++;
      self.amount_in_expected = ind.loadVariableUint(amount_in_len);
      ind += amount_in_len;
////          console.log("self.amount_in_expected:", self.amount_in_expected);
    }

    {
      uint amount_out_len = ind.loadUint8();
      ind++;
      self.amount_out_expected = ind.loadVariableUint(amount_out_len);
      ind += amount_out_len;
////          console.log("self.amount_out_expected:", self.amount_out_expected);
    }

    self.curve_pool = ind.loadAddress();
    ind += 20;

    self.curve_pool_source_ind = ind.loadUint8();
    ind++;

    self.curve_pool_target_ind = ind.loadUint8();
    ind++;

    return ind;
  }

  function prepare(CallType_7_vars memory self, V5ExecState.V5ExecState memory st) internal {
    if (self.token_source_ind == st.header.sourceArrInd) {
      self.amount_to_be_sent = self.amount_in_expected;
      if (st.header.doAcquireInputERC20Token) {
        TransferHelper.safeApprove(self.token_source, self.curve_pool, self.amount_to_be_sent);
        self.isNative = false;
        st.balances[self.token_source_ind] -= self.amount_to_be_sent;
      } else {
        if (self.token_source == Addrs.WETH9) {
          if (st.msgValueLeft >= self.amount_to_be_sent) {
            self.isNative = true;
            st.msgValueLeft -= self.amount_to_be_sent;
          } else {
            revert('CT7: msg.value insufficient');
          }
        } else {
          TransferHelper.safeTransferFrom(self.token_source, msg.sender, address(this), self.amount_to_be_sent);
          TransferHelper.safeApprove(self.token_source, self.curve_pool, self.amount_to_be_sent);
          self.isNative = false;
        }
      }
    } else {
      self.amount_to_be_sent = (self.amount_in_expected * st.totals[self.token_source_ind]) / st.expected[self.token_source_ind];
      TransferHelper.safeApprove(self.token_source, self.curve_pool, self.amount_to_be_sent);
      self.isNative = false;
      st.balances[self.token_source_ind] -= self.amount_to_be_sent;
    }
  }

  function doItFromInput(CallType_7_vars memory self, V5ExecState.V5ExecState memory st) internal returns (bool res) {
//    console.log('self.token_target:', self.token_target);
    uint balanceBefore;
    uint balanceAfter;
    if (self.curve_pool == Addrs.CURVE_USDT_WBTC_WETH_POOL) {
      if (self.token_target == Addrs.WETH9 && self.token_target_ind == st.header.targetArrInd && st.header.getNativeETH) {
        balanceBefore = address(this).balance;
        CurvePool_USDT_WBTC_WETH(self.curve_pool).exchange(self.curve_pool_source_ind, self.curve_pool_target_ind, self.amount_to_be_sent, 0, true);
        balanceAfter = address(this).balance;
      } else {
        balanceBefore = IERC20(self.token_target).balanceOf(address(this));
        CurvePool_USDT_WBTC_WETH(self.curve_pool).exchange{value: self.isNative ? self.amount_to_be_sent : 0}(self.curve_pool_source_ind, self.curve_pool_target_ind, self.amount_to_be_sent, 0, self.isNative);
        balanceAfter = IERC20(self.token_target).balanceOf(address(this));
      }
    } else if (self.curve_pool == Addrs.CURVE_DAI_USDC_USDT_POOL) {
      balanceBefore = IERC20(self.token_target).balanceOf(address(this));
      CurvePool_DAI_USDC_USDT(self.curve_pool).exchange(int128(uint128(self.curve_pool_source_ind)), int128(uint128(self.curve_pool_target_ind)), self.amount_to_be_sent, 0);
      balanceAfter = IERC20(self.token_target).balanceOf(address(this));
    } else {
      revert('unsupported CurvePool');
    }
    uint diff = balanceAfter - balanceBefore;
    // sent in the aftermath
    self.amount_out = diff;
//    console.log('diff:', diff);
//    if (self.token_source_ind != st.header.sourceArrInd || (self.token_source == Addrs.WETH9 && (msg.value != 0 || st.header.doPrefetchInputToken))) {
//      st.balances[self.token_source_ind] -= self.amount_to_be_sent;
//    }
    st.balances[self.token_target_ind] += diff;
    st.totals[self.token_target_ind] += diff;
//    console.log('self.token_target_ind:', self.token_target_ind);
    st.expected[self.token_target_ind] += self.amount_out_expected;
  }

//  function afterFromInput(CallType_7_vars memory self, V5ExecState.V5ExecState memory st) internal {
//    if (self.isNative) {
//
//    } else {
//    }
//    if (self.flags & CT_7_TO_SENDER > 0) {
//      TransferHelper.safeTransfer(self.token_target, msg.sender, self.amount_out);
////      st.totalTo += uint128(self.amount_out);
//    }
//  }
}

interface CurvePool_DAI_USDC_USDT {
  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

interface CurvePool_USDT_WBTC_WETH {
  function coins(uint256 i) external returns(address);
  function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external payable;
}

interface WETH9 {
  function deposit() external payable;
  function withdraw(uint256 amount) external;
}

library V5CallType_5_lib {
//  using SafeMath for uint;
  using CalldataLoader for uint;
//  using BytesLoader for uint;

  struct CallType_5_vars {
    uint flags;
    uint token_source_ind;
    uint token_target_ind;
    uint pool_fee;
    uint amount_in_expected;
    uint amount_out_expected;

    int specifiedAmount;

    bool isNative;
    bool fromSender;

    address token_source;
    address token_target;
    address univ3_pool;

    int dsa;
    int dta;
  }

  uint internal constant CT_5_FROM_SENDER = 1;
  uint internal constant CT_5_TO_SENDER = 2;

  function load(CallType_5_vars memory self, uint ind, uint tokens_start_ind, uint tokens_num) internal view returns(uint new_ind) {
    self.flags = ind.loadUint8();
    ind++;
//    console.log("flags:", self.flags);
    self.token_source_ind = ind.loadUint8();
    ind++;
//    console.log("self.token_source_ind:", self.token_source_ind);
    require(self.token_source_ind < tokens_num, "5SI");
    self.token_source = self.token_source_ind.loadTokenFromArrayV4(tokens_start_ind);

    self.token_target_ind = ind.loadUint8();
    ind++;
    require(self.token_target_ind < tokens_num, "5TI");
    self.token_target = self.token_target_ind.loadTokenFromArrayV4(tokens_start_ind);
    self.pool_fee = ind.loadUint24();
//    console.log("pool_fee:", self.pool_fee);
    ind += 3;
    {
      uint amount_in_len = ind.loadUint8();
      ind++;
      self.amount_in_expected = ind.loadVariableUint(amount_in_len);
      ind += amount_in_len;
    }
    {
      uint amount_out_len = ind.loadUint8();
      ind++;
      self.amount_out_expected = ind.loadVariableUint(amount_out_len);
      ind += amount_out_len;
    }
//    console.log("token_source:", self.token_source);
//    console.log("token_target:", self.token_target);
//    console.log("pool_fee:", self.pool_fee);
//    console.log("amount_in_expected:", self.amount_in_expected);
//    console.log("amount_out_expected:", self.amount_out_expected);
    return ind;
  }

  function prepare(CallType_5_vars memory self, V5ExecState.V5ExecState memory st) internal {
    self.univ3_pool = IUniswapV3Factory(Addrs.UNISWAP_V3_FACTORY).getPool(self.token_source, self.token_target, uint24(self.pool_fee)); 
//    console.log("univ3_pool:", self.univ3_pool);
    require(self.univ3_pool != address(0), '5ZPA');
    if (self.token_source_ind == st.header.sourceArrInd) {
      self.specifiedAmount = int256(self.amount_in_expected);
      if (st.header.doAcquireInputERC20Token) {
        self.isNative == false;
        self.fromSender = false;
        st.balances[self.token_source_ind] -= uint(self.specifiedAmount);
      } else {
        if (self.token_source == Addrs.WETH9) {
          if (st.msgValueLeft >= uint256(self.specifiedAmount)) {
            self.isNative = true;
            self.fromSender = false;
            st.msgValueLeft -= uint256(self.specifiedAmount);
          } else {
            revert('CT5: msg.value insufficient');
          }
        } else {
          self.isNative = false;
          self.fromSender = true;
        }
      }
    } else {
      self.specifiedAmount = int256((self.amount_in_expected * st.totals[self.token_source_ind]) / st.expected[self.token_source_ind]);
      self.isNative = false;
      self.fromSender = false;
      st.balances[self.token_source_ind] -= uint256(self.specifiedAmount);
    }
  }

  function doItFromInput(CallType_5_vars memory self, V5ExecState.V5ExecState memory st, bytes calldata data) internal {
//    self.univ3_pool = IUniswapV3Factory(Addrs.UNISWAP_V3_FACTORY).getPool(self.token_source, self.token_target, uint24(self.pool_fee)); 
////    console.log("univ3_pool:", self.univ3_pool);
//    require(self.univ3_pool != address(0), '5ZPA');
    bool zeroForOne = self.token_source < self.token_target;
    {
//      if (self.flags & V5CallType_5_lib.CT_5_FROM_SENDER != 0) {
//        st.totalFrom += uint128(self.amount_in_expected);
////        console.log("amount from msg.sender:", self.amount_in_expected);
//        self.specifiedAmount = int256(self.amount_in_expected);
//      } else {
//        self.specifiedAmount = int256((self.amount_in_expected * st.totals[self.token_source_ind]) / st.expected[self.token_source_ind]);
//      }
//      console.log("specifiedAmount:");
//      console.logInt(self.specifiedAmount);
//      console.log("total:     ", st.totals[self.token_target_ind]);
//      console.log("expected:  ", st.expected[self.token_target_ind]);
//      console.log("recipient: ", (self.flags & V5CallType_5_lib.CT_5_TO_SENDER) == 0 ? address(this) : st.msgsender);
      try IUniswapV3Pool(self.univ3_pool).swap(
//          (self.flags & V5CallType_5_lib.CT_5_TO_SENDER) == 0 ? address(this) : st.msgsender ,
          (self.token_target_ind != st.header.targetArrInd || (self.token_target == Addrs.WETH9 && st.header.getNativeETH)) ? address(this) : msg.sender,
          zeroForOne,
          self.specifiedAmount,
          zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
//          abi.encode(st, self, data)
          abi.encode(self.token_source, self.token_target, self.isNative, self.fromSender)
      ) returns (int256 da0, int256 da1) {
        if (zeroForOne) {
          (self.dsa, self.dta) = (da0, da1);
        } else {
          (self.dsa, self.dta) = (da1, da0);
        }
      } catch Error(string memory s) {
//        console.log("transfer failed");
////            console.log("expected balance: ", value_to_pay);
//        console.log("actual balance: ", uint256(st.balances[self.token_source_ind]));
        revert(s);
      }
    }
  }

  function afterFromInput(CallType_5_vars memory self, V5ExecState.V5ExecState memory st) internal {
//    console.log('dsa');
//    console.logInt(self.dsa);
//    console.log('dta');
//    console.logInt(self.dta);
//    if (self.token_source_ind != st.header.sourceArrInd || msg.value != 0 || st.header.doPrefetchInputToken) {
//      st.balances[self.token_source_ind] -= uint256(self.dsa);
//    }

    if (self.specifiedAmount < self.dsa) {
      uint diff = uint256(self.dsa - self.specifiedAmount);
      if (self.token_source_ind == st.header.sourceArrInd) {
        if (st.header.doAcquireInputERC20Token) {
          st.balances[self.token_source_ind] -= diff;
        } else {
          if (self.token_source == Addrs.WETH9) {
            if (st.msgValueLeft >= diff) {
              st.msgValueLeft -= diff;
            } else {
              revert('CT5: msg.value insufficient (after)');
            }
          } else {
            // skip
          }
        }
      } else {
        st.balances[self.token_source_ind] -= diff;
      }
    }

    if (self.token_target_ind == st.header.targetArrInd) {
      if (self.token_target == Addrs.WETH9 && st.header.getNativeETH) {
        st.ethAmountToUnwrap += uint256(-self.dta);
//        st.balances[st.token_target_ind] += uint256(-self.dta); // in case of ETH target, balance logs only the native ETH, i.e. the output of Curve only
      }
    } else {
      st.balances[self.token_target_ind] += uint256(-self.dta);
    }
    st.totals[self.token_target_ind] += uint256(-self.dta);
    st.expected[self.token_target_ind] += self.amount_out_expected;
  }
}

library V5ExecHeader {
  using CalldataLoader for uint;

  struct Header {
    uint8 slippage;
    uint8 tokensNum;
    uint8 numOfCalls;
    uint8 sourceArrInd;
    uint8 targetArrInd;
    bool fromInput;
    uint32 callArrOffset;
    uint32 tokensOffset;

    bool getNativeETH;
    bool doAcquireInputERC20Token;
  }

  function load(bytes calldata cdata) view internal returns (Header memory h, uint ind) {
    assembly {
      ind := cdata.offset
    }
    {
      uint _network = ind.loadUint16();
      ind += 2;
//      console.log("_network:", _network);
      require(_network == 1, "WRONGNETWORK");
      uint version = ind.loadUint8();
//    console.log("version:", version);
      ind++;
      require(version == 5, "WRONGVERSION");
    }
    h.fromInput = ind.loadUint8() > 0;
    ind++;
//    console.log("fromInput:", h.fromInput);
    h.slippage = uint8(ind.loadUint8());
    ind++;
//    console.log("slippage:", h.slippage);
    h.getNativeETH = bool(ind.loadUint8() != 0); //true;
    ind++;
    h.doAcquireInputERC20Token = bool(ind.loadUint8() != 0);//false;
    ind++;

    h.sourceArrInd = uint8(ind.loadUint8());
    ind++;
//    console.log("sourceArrInd:", h.sourceArrInd);
    h.targetArrInd = uint8(ind.loadUint8());
    ind++;

//    console.log("targetArrInd:", h.targetArrInd);
    h.tokensNum = uint8(ind.loadUint8());
    ind++;
    {
      uint tmp;
      assembly {
        tmp := sub(ind, cdata.offset)
      }
      h.tokensOffset = uint32(tmp);
    }
    ind += h.tokensNum * 20;
    h.numOfCalls = uint8(ind.loadUint8());// = uint8(data[ind]);
    ind++;
    {
      uint tmp;
      assembly {
        tmp := sub(ind, cdata.offset)
      }
      h.callArrOffset = uint32(tmp);
    }

//    h.msgValueLeft = msg.value;

  }

  function newState(Header memory h) view internal returns(V5ExecState.V5ExecState memory st) {
    st = V5ExecState.V5ExecState({
      totals: new uint256[](h.tokensNum),
      expected: new uint256[](h.tokensNum),
      balances: new uint256[](h.tokensNum),
//      totalFrom: 0,
//      totalTo: 0,
//      currentCallOffset: h.callArrOffset,
//      nextCallOffset: h.callArrOffset,
      callCounter: 0,
      msgsender: msg.sender,
      msgValueLeft: msg.value,
      ethAmountToUnwrap: 0,
      header: h
    });
  }
}

library V5ExecState {
  struct V5ExecState {
    uint256[] totals;
    uint256[] expected;
    uint256[] balances;
//    uint256 totalFrom;
//    uint256 totalTo;
// no need for FromInput
//    uint32 currentCallOffset;
//    uint32 nextCallOffset;
    uint callCounter;
    address msgsender;
    uint msgValueLeft;
    uint ethAmountToUnwrap;
    V5ExecHeader.Header header;
  }
}

library  V5Utils {
  function pay(
      address token,
      address payer,
      address recipient,
      uint256 value
  ) internal {
//      console.log("going to pay ... ");
      if (token == Addrs.WETH9 && address(this).balance >= value) {
          // pay with WETH9
          IWETH9(Addrs.WETH9).deposit{value: value}(); // wrap only what is needed to pay
          IWETH9(Addrs.WETH9).transfer(recipient, value);
      } else if (payer == address(this)) {
          // pay with tokens already in the contract (for the exact input multihop case)
//          console.log("from router");
//          console.log("token:", token);
//          console.log("value to pay: ", value);
//          console.log("actual balance: ", IERC20(token).balanceOf(address(this)));
//          try TransferHelper.safeTransfer(token, recipient, value) {
//          } catch Error(string memory s) {
//            value_to_pay = value;
//            revert(s);
//          }
          TransferHelper.safeTransfer(token, recipient, value);
      } else {
          // pull payment
//          console.log("from msg.sender");
//          console.log("token:", token);
//          console.log("payer:", payer);
//          console.log("value to pay: ", value);
//          (bool success_, bytes memory b_allowance) = token.staticcall(abi.encodeWithSelector(Selectors.ALLOWANCE_SELECTOR, payer, address(this)));
//          uint256 allowance = abi.decode(b_allowance, (uint256));
//          console.log('token:', token);
//          console.log('payer:', payer);
//          console.log('address(this):', address(this));
//          console.log("allowance:    ", allowance);
//          console.log('going to trasferFrom');
          TransferHelper.safeTransferFrom(token, payer, recipient, value);
//          console.log("trasfered: ", value);
      }
  }
}
