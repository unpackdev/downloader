// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1967Upgrade.sol";
import "./Ownable.sol";
import "./ERC1967Proxy.sol";

contract ProxyBridge is Ownable, ERC1967Proxy {
  constructor(address _logic, bytes memory data) ERC1967Proxy(_logic, data) {}

  modifier ifAdmin() {
    if (msg.sender == owner()) {
      _;
    } else {
      _fallback();
    }
  }

  function upgradeTo(address newImplementation) public ifAdmin {
    _upgradeTo(newImplementation);
  }

  function getImplementationAddress() public view returns (address) {
    return ERC1967Upgrade._getImplementation();
  }
}
