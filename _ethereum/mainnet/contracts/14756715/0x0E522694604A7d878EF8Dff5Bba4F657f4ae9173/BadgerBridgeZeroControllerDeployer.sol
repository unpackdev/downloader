// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./BadgerBridgeZeroController.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";

contract BadgerBridgeZeroControllerDeployer {
  address constant governance = 0x5E9B37149b7d7611bD0Eb070194dDA78EB11EfdC;
  event Deployment(address indexed proxy);
  constructor() {
    address logic = address(new BadgerBridgeZeroController());
    address proxy = address(new ProxyAdmin()); 
    ProxyAdmin(proxy).transferOwnership(governance);
    emit Deployment(address(new TransparentUpgradeableProxy(logic, proxy, abi.encodeWithSelector(BadgerBridgeZeroController.initialize.selector, governance, governance))));
    selfdestruct(msg.sender);
  }
}
