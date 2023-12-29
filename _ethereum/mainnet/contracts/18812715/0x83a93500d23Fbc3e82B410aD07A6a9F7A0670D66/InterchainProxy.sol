// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Proxy.sol";

/**
 * @title InterchainProxy
 * @notice This contract is a proxy for interchainTokenService and interchainTokenFactory.
 * @dev This contract implements Proxy.
 */
contract InterchainProxy is Proxy {
    constructor(address implementationAddress, address owner, bytes memory setupParams) Proxy(implementationAddress, owner, setupParams) {}
}
