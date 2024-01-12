//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./UUPSProxy.sol";

contract Proxy is UUPSProxy {
  // solhint-disable-next-line no-empty-blocks
  constructor(address firstImplementation) UUPSProxy(firstImplementation) {}
}
