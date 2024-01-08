// SPDX-License-Identifier: MIT
pragma solidity ^0.5.3;

import "./Proxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(Proxy proxy, address _mastercopy, bytes calldata initializer, uint256 saltNonce) external;
}

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <richard@gnosis.io>
/// @author Gas Save - <GasSave.org>
interface IProxy {
    function masterCopy() external view returns (address);
}

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IGSVEToken {
    function burnFrom(address account, uint256 amount) external;
}

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IGSVEBeacon {
    function initSafe(address owner, address safe) external;
}

/// @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <stefan@gnosis.pm>
/// @author Gas Save - <GasSave.org>
contract ProxyFactory {
    address public GSVEToken;
    address public GSVEBeacon;
    event ProxyCreation(Proxy proxy);
    
    /// @dev sets the addresses of the GSVE token AND GSVE Beacon. Used in the creation process
    constructor (address _GSVEToken, address _GSVEBeacon) public {
        GSVEToken = _GSVEToken;
        GSVEBeacon = _GSVEBeacon;
    }
    

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param masterCopy Address of master copy.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address masterCopy, bytes memory data)
        public
        returns (Proxy proxy)
    {
        proxy = new Proxy(masterCopy);
        if (data.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                if eq(call(gas, proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
            }
        emit ProxyCreation(proxy);
    }

    /// @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(Proxy).runtimeCode;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(Proxy).creationCode;
    }

    /// @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
    ///      This method is only meant as an utility to be called from other methods
    /// @param _mastercopy Address of master copy.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function deployProxyWithNonce(address _mastercopy, bytes memory initializer, uint256 saltNonce)
        internal
        returns (Proxy proxy)
    {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        bytes memory deploymentData = abi.encodePacked(type(Proxy).creationCode, uint256(_mastercopy));
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _mastercopy Address of master copy.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    /// BURNS GSVE IN THE PROCESS OF CREATING THE PROXY AND ADDS THE CREATED SAFE TO THE BEACON
    function createProxyWithNonce(address _mastercopy, bytes memory initializer, uint256 saltNonce)
        public
        returns (Proxy proxy)
    {
        IGSVEToken(GSVEToken).burnFrom(msg.sender, 50*10**18);
        proxy = deployProxyWithNonce(_mastercopy, initializer, saltNonce);
        if (initializer.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                if eq(call(gas, proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) { revert(0,0) }
            }

        IGSVEBeacon(GSVEBeacon).initSafe(msg.sender, address(proxy));
        emit ProxyCreation(proxy);
    }
}
