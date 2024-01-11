// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Ownable.sol";
import "./IBlockControlPolicy.sol";
import "./Governable.sol";
import "./PerVaultGatekeeper.sol";
import "./ISanctionsList.sol";

contract SanctionsListAccessControl is IBlockControlPolicy, PerVaultGatekeeper {
  address private sanctions;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _governance, address _sanctions) PerVaultGatekeeper(_governance) {
    sanctions = _sanctions;
  }

  function _blockedAccess(address _user) internal view returns (bool) {
    ISanctionsList sanctionsList = ISanctionsList(sanctions);
    return sanctionsList.isSanctioned(_user);
  }

  function blockedAccess(address _user, address) external view returns (bool) {
    return _blockedAccess(_user);
  }
}
