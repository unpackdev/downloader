// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./FauxblocksLib.sol";
import "./FundsManager.sol";
import "./FauxblocksLib.sol";
import "./IPolicy.sol";

contract FundsManagerPolicy is IPolicy {
  using FauxblocksLib for *;
  address public controller;
  address public operator;
  //This is the EOA address of the Labs Cream account (possibly the same as the admin)
  address public creamAddress;
  address public aaveAddress;
  address public admin;
  constructor(address _controller, address _admin, address _operator, address _creamAddress, address _aaveAddress) public {
    controller = _controller;
    operator = _operator;
    admin = _admin;
    creamAddress = _creamAddress;
    aaveAddress = _aaveAddress;
  }
  modifier onlyController {
    require(msg.sender == controller, "only controller");
    _;
  }
  function setAdmin(address _admin) public onlyController {
    admin = _admin;
  }
  function setOperator(address _operator) public onlyController {
    operator = _operator;
  }
  function setCreamAddress(address _creamAddress) public onlyController {
    creamAddress = _creamAddress;
  }
  function setAaveAddress(address _aaveAddress) public onlyController {
    aaveAddress = _aaveAddress;
  }
  function acceptTransaction(address sender, FauxblocksLib.Transaction memory trx) public override view returns (FauxblocksLib.TransactionType code, bytes memory context) {
    code = FauxblocksLib.TransactionType.REJECT;
    bytes4 signature = trx.data.toSignature();
    if (signature == FundsManager.stake.selector || signature == FundsManager.unstake.selector || signature == FundsManager.claim.selector) {
      if (sender == admin) {
        code = FauxblocksLib.TransactionType.DELEGATECALL;
      } else {
        context = bytes("must be called by admin");
      }
    } else if (signature == FundsManager.topUpAave_unstake.selector) {
      if (sender == admin || sender == operator) {
        code = FauxblocksLib.TransactionType.DELEGATECALL;
        context = abi.encode(aaveAddress);
      } else {
        context = bytes("must be called by operator or admin");
      }
    } else if (signature == FundsManager.topUpCream_unstake.selector) {
      if (sender == admin || sender == operator) {
        code = FauxblocksLib.TransactionType.DELEGATECALL;
        context = abi.encode(creamAddress);
      } else {
        context = bytes("must be called by operator or admin");
      }
    } else {
      code = FauxblocksLib.TransactionType.REJECT;
      context = bytes("invalid tx");
    }
  }
}
