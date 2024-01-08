// SPDX-License-Identifier: Apache-2.0

 pragma solidity >=0.8.0;

 import "./ERC1967Proxy.sol";

 contract LiquidityMiningProxy is ERC1967Proxy {
     constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}
 }