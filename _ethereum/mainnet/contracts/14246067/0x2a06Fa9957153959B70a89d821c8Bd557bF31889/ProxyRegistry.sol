//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IProxyRegistry.sol";
import "./AddressSet.sol";

/// @title ProxyRegistryManager
/// @notice a proxy registry is a registry of delegate proxies which have the ability to autoapprove transactions for some address / contract. Used by OpenSEA to enable feeless trades by a proxy account
contract ProxyRegistryManager is IProxyRegistryManager {

    // using the addressset library to store the addresses of the proxies
    using AddressSet for AddressSet.Set;

    // the set of registry managers able to manage this registry
    mapping(address => bool) internal registryManagers;

    // the set of proxy addresses
    AddressSet.Set private _proxyAddresses;

    /// @notice add a new registry manager to the registry
    /// @param newManager the address of the registry manager to add
    function addRegistryManager(address newManager) external virtual override {
        registryManagers[newManager] = true;
    }

    /// @notice remove a registry manager from the registry
    /// @param oldManager the address of the registry manager to remove
    function removeRegistryManager(address oldManager) external virtual override {
        registryManagers[oldManager] = false;
    }

    /// @notice check if an address is a registry manager
    /// @param _addr the address of the registry manager to check
    /// @return _isManager true if the address is a registry manager, false otherwise
    function isRegistryManager(address _addr)
    external
    virtual
    view
    override
    returns (bool _isManager) {
        return registryManagers[_addr];
    }

    /// @notice add a new proxy address to the registry
    /// @param newProxy the address of the proxy to add
    function addProxy(address newProxy) external virtual override {
        _proxyAddresses.insert(newProxy);
    }

    /// @notice remove a proxy address from the registry
    /// @param oldProxy the address of the proxy to remove
    function removeProxy(address oldProxy) external virtual override {
        _proxyAddresses.remove(oldProxy);
    }

    /// @notice check if an address is a proxy address
    /// @param proxy the address of the proxy to check
    /// @return _isProxy true if the address is a proxy address, false otherwise
    function isProxy(address proxy)
    external
    virtual
    view
    override
    returns (bool _isProxy) {
        _isProxy = _proxyAddresses.exists(proxy);
    }

    /// @notice get the count of proxy addresses
    /// @return _count the count of proxy addresses
    function allProxiesCount()
    external
    virtual
    view
    override
    returns (uint256 _count) {
        _count = _proxyAddresses.count();
    }

    /// @notice get the nth proxy address
    /// @param _index the index of the proxy address to get
    /// @return the nth proxy address
    function proxyAt(uint256 _index)
    external
    virtual
    view
    override
    returns (address) {
        return _proxyAddresses.keyAtIndex(_index);
    }

    /// @notice check if the proxy approves this request
    function _isApprovedForAll(address _owner, address _operator)
    internal
    view
    returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        for (uint256 i = 0; i < _proxyAddresses.keyList.length; i++) {
            IProxyRegistry proxyRegistry = IProxyRegistry(
                _proxyAddresses.keyList[i]
            );
            try proxyRegistry.proxies(_owner) returns (
                OwnableDelegateProxy thePr
            ) {
                if (address(thePr) == _operator) {
                    return true;
                }
            } catch {}
        }
        return false;
    }

}
