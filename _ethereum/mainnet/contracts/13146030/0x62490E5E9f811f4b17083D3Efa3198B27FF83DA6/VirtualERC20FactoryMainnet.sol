// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./VirtualERC20Factory.sol";

contract VirtualERC20FactoryMainnet is VirtualERC20Factory {
  /// @dev Initial owner is the habitat rollup bridge.
  function _INITIAL_OWNER () internal view virtual override returns (address) {
    return 0x96E471B5945373dE238963B4E032D3574be4d195;
  }
}
