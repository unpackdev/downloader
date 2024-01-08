// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";

import "./IVerifier.sol";
import "./PoofBase.sol";

contract PoofVal is PoofBase {
  using SafeMath for uint256;

  constructor(
    IVerifier[5] memory _verifiers,
    bytes32 _accountRoot
  ) PoofBase(_verifiers, _accountRoot) {}

  function deposit(bytes[3] memory _proofs, DepositArgs memory _args) external payable virtual {
    require(_args.debt == 0, "Cannot use debt for depositing");
    deposit(_proofs, _args, new bytes(0), TreeUpdateArgs(0, 0, 0, 0));
  }

  function deposit(
    bytes[3] memory _proofs,
    DepositArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) public payable virtual {
    beforeDeposit(_proofs, _args, _treeUpdateProof, _treeUpdateArgs);
    require(msg.value == _args.amount, "Specified amount must equal msg.value");
  }

  function withdraw(bytes[3] memory _proofs, WithdrawArgs memory _args) external virtual {
    require(_args.debt == 0, "Cannot use debt for withdrawing");
    withdraw(_proofs, _args, new bytes(0), TreeUpdateArgs(0, 0, 0, 0));
  }

  function withdraw(
    bytes[3] memory _proofs,
    WithdrawArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) public virtual {
    beforeWithdraw(_proofs, _args, _treeUpdateProof, _treeUpdateArgs);
    uint256 amount = _args.amount.sub(_args.extData.fee, "Amount should be greater than fee");
    if (amount > 0) {
      (bool ok, ) = _args.extData.recipient.call{value: amount}("");
      require(ok, "Failed to send amount to recipient");
    }
    if (_args.extData.fee > 0) {
      (bool ok, ) = _args.extData.relayer.call{value: _args.extData.fee}("");
      require(ok, "Failed to send fee to relayer");
    }
  }
}
