//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

//i mport "hardhat/console.sol";

//i mport "./libraries/BytesLib.sol";
import "./IUniswapV2Pair.sol";
import "./SafeMath.sol";
//i mport "./libraries/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
//i mport "./libraries/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "./IERC20.sol";
//i mport "./libraries/anyswap-v1-core/contracts/AnyswapV4CallProxy.sol";

import "./ETHRouter_V2_CalldataLoader.sol";
import "./ETHRouter_V2_types.sol";

import "./ETHRouter_V2_selectors.sol";

contract ETHRouter_V2 { //is IUniswapV2Callee, IUniswapV3SwapCallback {
  using SafeMath for uint;
  using SafeMath for int;
  using CalldataLoader for uint;
  using CallType_1_lib for CallType_1_lib.CallType_1_vars;
//  address current_pool;

  address public owner;
  uint public constant network = 1;

  uint public constant SLIPPAGE_LIMIT = 200;

  constructor() {
    owner = msg.sender;
  }

  modifier ownerOnly {
//////    console.log("owner: ", owner, " | msg.sender: ", msg.sender);
    require(owner == msg.sender);
    _;
  }

  function setOwner(address newOwner) external ownerOnly {
    owner = newOwner;
  }

  function exec(bytes calldata data) external returns (uint256) {
//    console.log("---exec V2---: data.length:", data.length);
    uint ind = 68;// = 0
    {
      uint _network = ind.loadUint16();
      ind += 2;
      require(network == _network, "WRONGNETWORK");
      uint version = ind.loadUint8();
      ind++;
      require(version == 2, "WRONGVERSION");
    }
    uint slippage = ind.loadUint8();
    ind++;
//    console.log("slippage:", slippage);
    uint tokens_num = ind.loadUint8();
    ind++;
//    console.log("tokens_num:", tokens_num);
//    uint tokens_start = ind; // just shr( ... ) instead of shr(shl( ... )) // ind + 68 - 12;
//    console.log("ind:", ind);
    ind += tokens_num.mul(20);
//    for (uint j = 0; j < tokens_num; j++) {
////      console.log(j, ":", j.loadTokenFromArray());
//    }
    uint[] memory balances = new uint[](tokens_num);
//    for (uint i = 0; i < tokens_num; i++) {
//      balances[i] = 0;
//    }
//    console.log("ind:", ind);
    uint num_of_calls = ind.loadUint8();// = uint8(data[ind]);
    ind++;
//    console.log("num_of_calls:", num_of_calls);
    for (uint i = 0; i < num_of_calls; i++) {
      uint calltype = ind.loadUint8();// = uint8(data[ind]);
      ind++;
      if (calltype == 1) { // transfer to univ2-like pair and swap
//        console.log("\ncalltype == 1");
        CallType_1_lib.CallType_1_vars memory vars;
        ind = vars.load(ind, tokens_num);
        
//        uint available_amount;
        if (vars.flags & CallType_1_lib.CT_1_FROM_SENDER != 0) {
//          available_amount = vars.amount_in_expected;
//          console.log("allowed balanceOf:", IERC20(vars.token_source).allowance(msg.sender, address(this)));
          vars.amount_to_be_sent = vars.amount_in_expected;
        } else {
          uint available_amount = balances[vars.token_source_ind];
//          console.log("available_amount:", available_amount);
          {
            uint limit = vars.amount_in_expected.mul(SLIPPAGE_LIMIT.sub(slippage));
            limit = limit.div(SLIPPAGE_LIMIT);
            if (vars.amount_in_expected > 1000) {
              require(available_amount > limit, "1S"); 
            } else {
              if (available_amount == 0) {
                continue; // skip since it's just dust
              }
              //pass since it's supposedly just dust
            }
          }

          vars.amount_to_be_sent = available_amount > vars.amount_in_expected ? vars.amount_in_expected : available_amount;
//          console.log("balanceOf:", IERC20(vars.token_source).balanceOf(address(this)));
        }

        vars.doIt();

        balances[vars.token_source_ind] -= vars.minus_source; 
        balances[vars.token_target_ind] += vars.plus_target;
      } else if (calltype == 2) { //transfer funds to msg.sender
//        console.log("\ncalltype == 2");
        uint token_ind = ind.loadUint8();
        ind++;
//        console.log("token_ind:", token_ind);
        require(token_ind < tokens_num, "2TO");
        address token = token_ind.loadTokenFromArray();
        uint amount_expected;
        {
          uint amount_len = ind.loadUint8();
          ind++;
          amount_expected = ind.loadVariableUint(amount_len);
          ind += amount_len;
        }
//        console.log("amount_expected:", amount_expected);
//        console.log("balances[token_ind]:", balances[token_ind]);
        require(balances[token_ind] >= amount_expected.mul(SLIPPAGE_LIMIT.sub(slippage)).div(SLIPPAGE_LIMIT), "2S");
        (bool success, ) = token.call(abi.encodeWithSelector(Selectors.TRANSFER_SELECTOR, msg.sender, balances[token_ind]));
        require(success, "2TR");
        balances[token_ind] = 0; // the order is ok since it is not in storage
      } else if (calltype == 4) { //fetch funds from msg.sender
//        console.log("\ncalltype == 4");
        uint token_ind = ind.loadUint8();
        ind++;
//        console.log("token_ind:", token_ind);
        require(token_ind < tokens_num, "4TO");
        address token = token_ind.loadTokenFromArray();
//        console.log("token:", token);
        uint amount;
        {
          uint amount_len = ind.loadUint8();
          ind++;
          amount = ind.loadVariableUint(amount_len);
          ind += amount_len;
        }
//        console.log("amount:", amount);
        (bool success, ) = token.call(abi.encodeWithSelector(Selectors.TRANSFERFROM_SELECTOR, msg.sender, address(this), amount));
        require(success, "4TR");
        balances[token_ind] += amount;
//        console.log("balanceOf:", IERC20(token).balanceOf(address(this)));
      } else if (calltype == 3) { // uniV2swap just swap
//        console.log("\ncalltype == 3");
        revert("CT3"); // reserved for future
      } else if (calltype == 0) { // exec
//        console.log("\ncalltype == 0");
        require(msg.sender == owner, "OWN");
        address addr = ind.loadAddress();
        ind += 20;
        uint len = ind.loadUint16();
        ind += 2;
        uint start = ind.sub(68);
        (bool success, ) = addr.call(data[start : start + len]);
        require(success);
      } else {
//        console.log("\ncalltype ==", calltype);
        revert("CT");
      }
    }
    return ind;
  }

  function calcUniswapV2Out(uint r0, uint r1, uint a0) pure private returns (uint a1) {
    uint numer = r1.mul(a0).mul(997);
    uint denom = r0.mul(1000).add(a0.mul(997));
    a1 = numer.div(denom);
  }
}
