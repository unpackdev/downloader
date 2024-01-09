// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./Automate.sol";

// solhint-disable no-empty-blocks
// solhint-disable avoid-tx-origin
contract AutomateMock is Automate {
  address public staking;

  uint256 public pool;

  constructor(address _info) Automate(_info) {}

  function init(address _staking, uint256 _pool) external initializer {
    require(!_initialized || staking == _staking, "AutomateMock::init: reinitialize staking address forbidden");
    staking = _staking;
    pool = _pool;
  }

  function run(
    uint256 gasFee,
    uint256 x,
    uint256 y
  ) external bill(gasFee, "AutomateMock.run") returns (uint256) {
    return x + y;
  }
}
