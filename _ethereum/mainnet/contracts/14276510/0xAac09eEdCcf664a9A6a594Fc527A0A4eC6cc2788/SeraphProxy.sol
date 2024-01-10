// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "TransparentUpgradeableProxy.sol";

/**
 * @notice This is the proxy address that the clients will use on their contracts. It will be fixed
 * and never change. Only the Seraph implementation itself will be changed if code needs to be
 * upgraded. The storage for Seraph will reside in this contract. To take care of storage layout
 * the SeraphStorage contract exists.
 *
 * @dev Seraph will be executed though a Proxy with a fixed address that all the clients will know
 * and use to interact with Seraph. Transparent Upgradable Proxy will be used so Seraph code can be
 * later upgraded without affecting the fixed interface address. Furthermore, administrative task on
 * the proxy itself (SeraphProxy) will be delegated to a ProxyAdmin contract, owned and administred
 * by Halborn using a Multisig wallet, as suggested on the transparent proxy pattern. More information
 * can be found on https://blog.openzeppelin.com/the-transparent-proxy-pattern/
 */
contract SeraphProxy is TransparentUpgradeableProxy {

    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) {}

}
