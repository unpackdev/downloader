//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// Based off of https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b/
///   - but removes the _contractURI bits
///   - and makes it abstract
/// @title OpenSea contract helper that defines a few things
/// @author Simon Fremaux (@dievardump)
/// @dev This is a contract used to add OpenSea's
///      gas-less trading and contractURI support
abstract contract OpenSeaTradable {
    address private _proxyRegistry;

    /// @notice Returns the current OS proxyRegistry address registered
    function openSeaProxyRegistry() public view returns (address) {
        return _proxyRegistry;
    }

    /// @notice Helper allowing OpenSea gas-less trading by verifying who's operator
    ///         for owner
    /// @dev Allows to check if `operator` is owner's OpenSea proxy on eth mainnet / rinkeby
    ///      or to check if operator is OpenSea's proxy contract on Polygon and Mumbai
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function _isOwnersOpenSeaProxy(address owner, address operator) internal virtual view
        returns (bool)
    {
        address proxyRegistry_ = _proxyRegistry;

        // if we have a proxy registry
        if (proxyRegistry_ != address(0)) {
            address ownerProxy = ProxyRegistry(proxyRegistry_).proxies(owner);
            return ownerProxy == operator;
        }

        return false;
    }


    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal virtual {
        _proxyRegistry = proxyRegistryAddress;
    }
}

contract ProxyRegistry {
    mapping(address => address) public proxies;
}
