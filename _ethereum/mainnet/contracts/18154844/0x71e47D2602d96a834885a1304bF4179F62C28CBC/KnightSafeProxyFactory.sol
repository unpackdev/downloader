// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./KnightSafeProxy.sol";

/**
 * @title KnightSafeProxyFactory
 * @notice A factory contract that allow user to create new KnightSafeProxy contract
 */
contract KnightSafeProxyFactory {
    event ProxyCreation(KnightSafeProxy proxy, address indexed implementation);

    /**
     * @notice Create a new KnightSafeProxy contract
     * @param implementation Address of implementation contract
     * @param data Payload for a message call to be sent to a new proxy contract
     */
    function createProxy(address implementation, bytes memory data) public returns (KnightSafeProxy proxy) {
        proxy = new KnightSafeProxy(implementation);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, implementation);
    }
}
