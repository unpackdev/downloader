// SPDX-License-Identifier: MIT

/*

  Proxy registry interface.

*/

pragma solidity 0.8.4;

import "./OwnableDelegateProxy.sol";

/**
 * @title IProxyRegistry
 * @author Wyvern Protocol Developers
 */
interface IProxyRegistry {
    function delegateProxyImplementation() external returns (address);

    function proxies(address owner) external view returns (OwnableDelegateProxy);
}
