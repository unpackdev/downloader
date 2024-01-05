// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./TokamakNFT.sol";

contract TokamakNFTMinter is AccessControl {
  TokamakNFT private _tokamakNFT;

  constructor(address nft, address admin) {
    _tokamakNFT = TokamakNFT(nft);

    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  modifier onlyAdmin {
      require(isAdmin(msg.sender), "Only admin can use.");
      _;
  }

  /**
   * @dev Returns true if msg.sender has an ADMIN role.
   */
  function isAdmin(address user) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, user);
  }

  /**
   * @dev Transfers the rights from current admin to a new admin.
   */
  function transferAdminRights(address user) external onlyAdmin {
    grantRole(DEFAULT_ADMIN_ROLE, user);
    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /**
   * @dev Mints tokens for array of addresses.
   */
  function mintBatch(address[] calldata accounts, string memory eventName) external onlyAdmin {
    for (uint i = 0; i < accounts.length; ++i) {
      _tokamakNFT.mintToken(accounts[i], eventName);
    }
  }
}