// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

import "./PoofVal.sol";
import "./IVerifier.sol";
import "./IWERC20Val.sol";

contract PoofValLendable is PoofVal {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IWERC20Val public debtToken;

  constructor(
    IWERC20Val _debtToken,
    IVerifier[5] memory _verifiers,
    bytes32 _accountRoot
  ) PoofVal(_verifiers, _accountRoot) {
    debtToken = _debtToken;
  }

  function deposit(bytes[3] memory _proofs, DepositArgs memory _args) external payable override {
    deposit(_proofs, _args, new bytes(0), TreeUpdateArgs(0, 0, 0, 0));
  }

  function deposit(
    bytes[3] memory _proofs,
    DepositArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) public payable override {
    beforeDeposit(_proofs, _args, _treeUpdateProof, _treeUpdateArgs);
    uint256 underlyingAmount = debtToken.debtToUnderlying(_args.amount);
    require(msg.value >= underlyingAmount, "Specified amount must equal msg.value");
    debtToken.wrap{value: underlyingAmount}();
    (bool ok, ) = 
      msg.sender.call{value: address(this).balance}(""); 
    require(ok, "Failed to refund leftover balance to caller");
  }

  function withdraw(bytes[3] memory _proofs, WithdrawArgs memory _args) external override {
    withdraw(_proofs, _args, new bytes(0), TreeUpdateArgs(0, 0, 0, 0));
  }

  function withdraw(
    bytes[3] memory _proofs,
    WithdrawArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) public override {
    beforeWithdraw(_proofs, _args, _treeUpdateProof, _treeUpdateArgs);
    require(_args.amount >= _args.extData.fee, "Fee cannot be greater than amount");
    uint256 underlyingAmount = debtToken.debtToUnderlying(_args.amount.sub(_args.extData.fee));
    uint256 underlyingFeeAmount = debtToken.debtToUnderlying(_args.extData.fee);
    debtToken.unwrap(_args.amount);

    if (underlyingAmount > 0) {
      (bool ok, ) = _args.extData.recipient.call{value: underlyingAmount}("");
      require(ok, "Failed to send amount to recipient");
    }
    if (underlyingFeeAmount > 0) {
      (bool ok, ) = _args.extData.relayer.call{value: underlyingFeeAmount}("");
      require(ok, "Failed to send fee to relayer");
    }
  }

  function unitPerUnderlying() public view override returns (uint256) {
    return debtToken.underlyingToDebt(1);
  }

  receive() external payable {}
}

