// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Context.sol";
import "./Registrar.sol";

contract Governable is Context {

  address internal _governanceAddress;

  constructor() {}

  modifier onlyGovernance() {
    require(_governanceAddress == _msgSender(), "Unauthorized");
    _;
  }

  function _updateGovernable(Registrar registrar) internal {
    _governanceAddress = registrar.getVETHGovernance();
  }

  function getGovernanceAddress() external view returns (address) {
    return _governanceAddress;
  }
}