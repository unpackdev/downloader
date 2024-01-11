// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./IGatekeeperable.sol";
import "./Governable.sol";

contract PerVaultGatekeeper is Governable {
  // solhint-disable-next-line no-empty-blocks
  constructor(address _governance) Governable(_governance) {}

  /// @dev works with any contract that implements the IGatekeeperable interface.
  function _onlyGovernanceOrGatekeeper(address _pool) internal view {
    require(_pool != address(0), "!address");
    address gatekeeper = IGatekeeperable(_pool).gatekeeper();
    require(_msgSender() == governance || (gatekeeper != address(0) && _msgSender() == gatekeeper), "not authorised");
  }
}
