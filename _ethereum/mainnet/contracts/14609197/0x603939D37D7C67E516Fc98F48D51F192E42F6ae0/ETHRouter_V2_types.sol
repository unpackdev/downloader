//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "./console.sol";

import "./SafeMath.sol";

import "./IERC20.sol";

import "./ETHRouter_V2_selectors.sol";
import "./ETHRouter_V2_CalldataLoader.sol";

library CallType_1_lib {
  using SafeMath for uint;
  using CalldataLoader for uint;

  struct CallType_1_vars {
    uint flags;
//    uint next_uniswap_v2_token_ind;
//    uint uniswap_v2_or_sushi; // 0 uniswap V2, 1 sushi
    uint token_source_ind;
    uint token_target_ind;
    address token_source;
    address token_target;
    uint amount_in_expected;
    uint amount_out_expected;
    uint amount_to_be_sent;
    address v2pair;
    uint amount_out;
    uint minus_source;
    uint plus_target;
  }

  using CallType_1_lib for CallType_1_vars;

  uint internal constant CT_1_FROM_SENDER = 1;
  uint internal constant CT_1_TO_SENDER = 2;
  uint internal constant CT_1_UNISWAP_OR_SUSHISWAP = 4; // false == uniswap, true == sushiswap
  uint internal constant CT_1_SUSHISWAP = 4;

  function load(CallType_1_vars memory self, uint ind, uint tokens_num) internal pure returns (uint new_ind) {
    self.flags = ind.loadUint8();
    ind++;
//        console.log("self.flags:", self.flags);

    self.token_source_ind = ind.loadUint8();// = uint8(data[ind]);
    ind++;
//        console.log("self.token_source_ind:", self.token_source_ind);
    require(self.token_source_ind < tokens_num, "1SI");
    self.token_source = self.token_source_ind.loadTokenFromArray();
//        console.log("self.token_source:", self.token_source);

    self.token_target_ind = ind.loadUint8(); //= uint8(data[ind]);
    ind++;
//        console.log("self.token_target_ind:", self.token_target_ind);
    require(self.token_target_ind < tokens_num, "1TI");
    self.token_target = self.token_target_ind.loadTokenFromArray();
//        console.log("self.token_target:", self.token_target);

    {
      uint amount_in_len = ind.loadUint8();// = uint(uint8(data[ind]));
      ind++;
      self.amount_in_expected = ind.loadVariableUint(amount_in_len);
      ind += amount_in_len;
//          console.log("self.amount_in_expected:", self.amount_in_expected);
    }

    {
      uint amount_out_len = ind.loadUint8();
      ind++;
      self.amount_out_expected = ind.loadVariableUint(amount_out_len);
      ind += amount_out_len;
//          console.log("self.amount_out_expected:", self.amount_out_expected);
    }
    return ind;
  }

  function doIt(CallType_1_vars memory self) internal {
//    console.log("doIt_");
    if (self.token_source < self.token_target) {
      self.getUniV2Pair_direct_order();
      self.UniV2CalcAmount1();
      if (self.amount_out == 0) {
        return;
      }
      self.transferToUniV2Pair();
      self.fetchFromUniV2Pair_1();
    } else {
      self.getUniV2Pair_reverse_order();
      self.UniV2CalcAmount0();
      if (self.amount_out == 0) {
        return;
      }
      self.transferToUniV2Pair();
      self.fetchFromUniV2Pair_0();
    }
  }

  function getFactory(CallType_1_vars memory self) internal pure returns(address) {
    address factory;
    uint switcher = self.flags & CT_1_UNISWAP_OR_SUSHISWAP;
    if (switcher == 0) {
      factory = Addrs.UNISWAP_V2_FACTORY;
    } else if (switcher != 0) {
      factory = Addrs.SUSHI_FACTORY;
    } else {
      revert("UOS");
    }
    return factory;
  }

  function getUniV2Pair_direct_order(CallType_1_vars memory self) internal view {
//    console.log("CT_1_lib.getuniV2Pair_direct_order");
    (bool success, bytes memory res) = self.getFactory().staticcall(abi.encodeWithSelector(Selectors.UNISWAP_V2_GETPAIR_SELECTOR, self.token_source, self.token_target));
    require(success, "1GPDO");
    address v2pair;
    assembly {
      v2pair := mload(add(res, 32))
    }
    require(v2pair != address(0), "1PRDO");
    self.v2pair = v2pair;
  }

  function getUniV2Pair_reverse_order(CallType_1_vars memory self) internal view {
//    console.log("CT_1_lib.getuniV2Pair_reverse_order");
    (bool success, bytes memory res) = self.getFactory().staticcall(abi.encodeWithSelector(Selectors.UNISWAP_V2_GETPAIR_SELECTOR, self.token_target, self.token_source));
    require(success, "1GPRO");
    address v2pair;
    assembly {
      v2pair := mload(add(res, 32))
    }
    require(v2pair != address(0), "1PRRO");
    self.v2pair = v2pair;
  }

  function transferToUniV2Pair(CallType_1_vars memory self) internal {
    if (self.flags & CT_1_FROM_SENDER != 0) {
      self.transferToUniV2Pair_from_sender();
      self.minus_source = 0;
    } else {
      self.transferToUniV2Pair_from_this();
      self.minus_source = self.amount_to_be_sent;
    }
  }

  function transferToUniV2Pair_from_this(CallType_1_vars memory self) internal {
//    console.log("transferToUniV2Pair_from_this");
    (bool success, ) = self.token_source.call(abi.encodeWithSelector(Selectors.TRANSFER_SELECTOR, self.v2pair, self.amount_to_be_sent));
    require(success, "1TTUV2");
  }

  function transferToUniV2Pair_from_sender(CallType_1_vars memory self) internal {
//    console.log("transferToUniV2Pair from sender");
    (bool success, ) = self.token_source.call(abi.encodeWithSelector(Selectors.TRANSFERFROM_SELECTOR, msg.sender, self.v2pair, self.amount_to_be_sent));
    require(success, "1TTUV2F");
  }

  function fetchFromUniV2Pair_0(CallType_1_vars memory self) internal {
    if (self.flags & CT_1_TO_SENDER != 0) {
      self.fetchFromUniV2Pair_0_to_sender();
      self.plus_target = 0;
    } else {
      self.fetchFromUniV2Pair_0_to_this();
      self.plus_target = self.amount_out;
    }
  }

  function fetchFromUniV2Pair_1(CallType_1_vars memory self) internal {
    if (self.flags & CT_1_TO_SENDER != 0) {
      self.fetchFromUniV2Pair_1_to_sender();
      self.plus_target = 0;
    } else {
      self.fetchFromUniV2Pair_1_to_this();
      self.plus_target = self.amount_out;
    }
  }

  function fetchFromUniV2Pair_0_to_this(CallType_1_vars memory self) internal {
//    console.log("fetchFromUniV2Pair_0_to_this");
    (bool success, ) = self.v2pair.call(abi.encodeWithSelector(Selectors.UNISWAP_V2_PAIR_SWAP_SELECTOR, self.amount_out, 0, address(this), new bytes(0)));
    require(success, "1F0FUV2");
  }

  function fetchFromUniV2Pair_1_to_this(CallType_1_vars memory self) internal {
//    console.log("fetchFromUniV2Pair_1_to_this");
    (bool success, ) = self.v2pair.call(abi.encodeWithSelector(Selectors.UNISWAP_V2_PAIR_SWAP_SELECTOR, 0, self.amount_out, address(this), new bytes(0)));
    require(success, "1F1FUV2");
  }

  function fetchFromUniV2Pair_0_to_sender(CallType_1_vars memory self) internal {
//    console.log("fetchFromUniV2Pair_0_to_sender");
    (bool success, ) = self.v2pair.call(abi.encodeWithSelector(Selectors.UNISWAP_V2_PAIR_SWAP_SELECTOR, self.amount_out, 0, msg.sender, new bytes(0)));
    require(success, "1F0FUV2L");
  }

  function fetchFromUniV2Pair_1_to_sender(CallType_1_vars memory self) internal {
//    console.log("fetchFromUniV2Pair_1_to sender");
    (bool success, ) = self.v2pair.call(abi.encodeWithSelector(Selectors.UNISWAP_V2_PAIR_SWAP_SELECTOR, 0, self.amount_out, msg.sender, new bytes(0)));
    require(success, "1F1FUV2L");
  }

  function UniV2CalcAmount0(CallType_1_vars memory self) view internal {
    (bool success, bytes memory res) = self.v2pair.staticcall(abi.encodeWithSelector(Selectors.UNISWAP_V2_GETRESERVES_SELECTOR));
    require(success, "1GR0");
    (uint112 reserve_0, uint112 reserve_1, ) = abi.decode(res, (uint112, uint112, uint32));
    self.amount_out = calcUniswapV2Out(reserve_1, reserve_0, self.amount_to_be_sent);
  }

  function UniV2CalcAmount1(CallType_1_vars memory self) view internal {
    (bool success, bytes memory res) = self.v2pair.staticcall(abi.encodeWithSelector(Selectors.UNISWAP_V2_GETRESERVES_SELECTOR));
    require(success, "1GR1");
    (uint112 reserve_0, uint112 reserve_1, ) = abi.decode(res, (uint112, uint112, uint32));
    self.amount_out = calcUniswapV2Out(reserve_0, reserve_1, self.amount_to_be_sent);
  }

  function calcUniswapV2Out(uint r0, uint r1, uint a0) pure private returns (uint a1) {
    uint numer = r1.mul(a0).mul(997);
    uint denom = r0.mul(1000).add(a0.mul(997));
    a1 = numer.div(denom);
  }
}
