//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

import "./Common.sol";
import "./IAccountImplementation.sol";
import "./IAccountGuard.sol";
import "./ServiceRegistry.sol";
import "./Common.sol";
import "./IDSProxy.sol";

contract ProxyPermission {
  IDSGuardFactory internal immutable dsGuardFactory;
  bytes4 public constant ALLOWED_METHOD_HASH = bytes4(keccak256("execute(address,bytes)"));

  constructor(address _dsGuardFactory) {
    dsGuardFactory = IDSGuardFactory(_dsGuardFactory);
  }

  function givePermission(bool isDPMProxy, address _contractAddr) public {
    if (isDPMProxy) {
      // DPM permission
      IAccountGuard(IAccountImplementation(address(this)).guard()).permit(
        _contractAddr,
        address(this),
        true
      );
    } else {
      // DSProxy permission
      address currAuthority = address(IDSAuth(address(this)).authority());
      IDSGuard guard = IDSGuard(currAuthority);
      if (currAuthority == address(0)) {
        guard = dsGuardFactory.newGuard();
        IDSAuth(address(this)).setAuthority(IDSAuthority(address(guard)));
      }

      if (!guard.canCall(_contractAddr, address(this), ALLOWED_METHOD_HASH)) {
        guard.permit(_contractAddr, address(this), ALLOWED_METHOD_HASH);
      }
    }
  }

  function removePermission(bool isDPMProxy, address _contractAddr) public {
    if (isDPMProxy) {
      // DPM permission
      IAccountGuard(IAccountImplementation(address(this)).guard()).permit(
        _contractAddr,
        address(this),
        false
      );
    } else {
      // DSProxy permission
      address currAuthority = address(IDSAuth(address(this)).authority());
      if (currAuthority == address(0)) {
        return;
      }
      IDSGuard guard = IDSGuard(currAuthority);
      guard.forbid(_contractAddr, address(this), ALLOWED_METHOD_HASH);
    }
  }
}
