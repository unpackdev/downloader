// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import "./IERC165.sol";
import "./IProxyFactory.sol";

/**
 * @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
 */
contract LaserProxyFactory is IProxyFactory {
    address public immutable singleton;

    /**
     * @param _singleton Master copy of the proxy.
     */
    constructor(address _singleton) {
        // Laser Wallet contract: bytes4(keccak256("I_AM_LASER"))
        if (!IERC165(_singleton).supportsInterface(0xae029e0b))
            revert ProxyFactory__constructor__invalidSingleton();
        singleton = _singleton;
    }

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     * @param data Payload for message call sent to new proxy contract.
     */
    function createProxy(bytes memory data)
        external
        returns (LaserProxy proxy)
    {
        proxy = new LaserProxy(singleton);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(
                    call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0),
                    0
                ) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(address(proxy), singleton);
    }

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     * @param initializer Payload for message call sent to new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function createProxyWithNonce(bytes memory initializer, uint256 saltNonce)
        external
        returns (LaserProxy proxy)
    {
        proxy = deployProxyWithNonce(initializer, saltNonce);

        if (initializer.length > 0)
            assembly {
                if eq(
                    call(
                        gas(),
                        proxy,
                        0,
                        add(initializer, 0x20),
                        mload(initializer),
                        0,
                        0
                    ),
                    0
                ) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(address(proxy), singleton);
    }

    /**
     * @dev Precomputes the address of a proxy that is created through 'create2'.
     */
    function preComputeAddress(bytes memory initializer, uint256 saltNonce)
        external
        view
        returns (address)
    {
        bytes memory creationCode = proxyCreationCode();
        bytes memory data = abi.encodePacked(
            creationCode,
            uint256(uint160(singleton))
        );

        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), saltNonce)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(data))
        );

        return address(uint160(uint256(hash)));
    }

    /**
     * @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
     */
    function proxyRuntimeCode() external pure returns (bytes memory) {
        return type(LaserProxy).runtimeCode;
    }

    /**
     *  @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
     */
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(LaserProxy).creationCode;
    }

    /**
     * @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
     * This method is only meant as an utility to be called from other methods.
     * @param initializer Payload for message call sent to new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function deployProxyWithNonce(bytes memory initializer, uint256 saltNonce)
        internal
        returns (LaserProxy proxy)
    {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), saltNonce)
        );

        bytes memory deploymentData = abi.encodePacked(
            type(LaserProxy).creationCode,
            uint256(uint160(singleton))
        );
        assembly {
            proxy := create2(
                0x0,
                add(0x20, deploymentData),
                mload(deploymentData),
                salt
            )
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }
}
