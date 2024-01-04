// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./AdministrateeInterface.sol";
import "./Ownable.sol";

contract FinancialContractsAdmin is Ownable {
  function callEmergencyShutdown(address financialContract) external onlyOwner {
    AdministrateeInterface administratee =
      AdministrateeInterface(financialContract);
    administratee.emergencyShutdown();
  }

  function callRemargin(address financialContract) external onlyOwner {
    AdministrateeInterface administratee =
      AdministrateeInterface(financialContract);
    administratee.remargin();
  }
}
