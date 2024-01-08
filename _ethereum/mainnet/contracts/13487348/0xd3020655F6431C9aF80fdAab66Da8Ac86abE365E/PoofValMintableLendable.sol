// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

import "./PoofValLendable.sol";
import "./IVerifier.sol";
import "./IWERC20Val.sol";

contract PoofValMintableLendable is PoofValLendable, ERC20 {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    IWERC20Val _debtToken,
    IVerifier[5] memory _verifiers,
    bytes32 _accountRoot
  ) ERC20(_tokenName, _tokenSymbol) PoofValLendable(_debtToken, _verifiers, _accountRoot) {}

  function burn(bytes[3] memory _proofs, DepositArgs memory _args) external {
    burn(_proofs, _args, new bytes(0), TreeUpdateArgs(0, 0, 0, 0));
  }

  function burn(
    bytes[3] memory _proofs,
    DepositArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) public {
    beforeDeposit(_proofs, _args, _treeUpdateProof, _treeUpdateArgs);
    require(_args.amount == 0, "Cannot use amount for burning");
    _burn(msg.sender, _args.debt);
  }

  function mint(bytes[3] memory _proofs, WithdrawArgs memory _args) external {
    mint(_proofs, _args, new bytes(0), TreeUpdateArgs(0, 0, 0, 0));
  }

  function mint(
    bytes[3] memory _proofs,
    WithdrawArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) public {
    beforeWithdraw(_proofs, _args, _treeUpdateProof, _treeUpdateArgs);
    require(_args.amount == _args.extData.fee, "Amount can only be used for fee");
    if (_args.amount > 0) {
      uint256 underlyingFeeAmount = debtToken.debtToUnderlying(_args.extData.fee);
      debtToken.unwrap(_args.amount);
      if (underlyingFeeAmount > 0) {
        (bool ok, ) = _args.extData.relayer.call{value: underlyingFeeAmount}("");
        require(ok, "Failed to send fee to relayer");
      }
    }
    if (_args.debt > 0) {
      _mint(_args.extData.recipient, _args.debt);
    }
  }

  function underlyingBalanceOf(address owner) external view returns (uint256) {
    uint256 balanceOf = balanceOf(owner);
    return debtToken.debtToUnderlying(balanceOf);
  }
}

