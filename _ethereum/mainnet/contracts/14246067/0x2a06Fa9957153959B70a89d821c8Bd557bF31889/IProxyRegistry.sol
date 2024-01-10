//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface OwnableDelegateProxy {}

/**
 * @dev a registry of proxies
 */
interface IProxyRegistry {

    function proxies(address _owner) external view returns (OwnableDelegateProxy);

}

/// @notice a proxy registry is a registry of delegate proxies which have the ability to autoapprove transactions for some address / contract. Used by OpenSEA to enable feeless trades by a proxy account
interface IProxyRegistryManager {

    /// @notice add a new registry manager to the registry
    /// @param newManager the address of the registry manager to add
    function addRegistryManager(address newManager) external;

   /// @notice remove a registry manager from the registry
    /// @param oldManager the address of the registry manager to remove
    function removeRegistryManager(address oldManager) external;

    /// @notice check if an address is a registry manager
    /// @param _addr the address of the registry manager to check
    /// @return _isRegistryManager true if the address is a registry manager, false otherwise
    function isRegistryManager(address _addr)
        external
        view
        returns (bool _isRegistryManager);

    /// @notice add a new proxy address to the registry
    /// @param newProxy the address of the proxy to add
    function addProxy(address newProxy) external;

    /// @notice remove a proxy address from the registry
    /// @param oldProxy the address of the proxy to remove
    function removeProxy(address oldProxy) external;

    /// @notice check if an address is a proxy address
    /// @param _addr the address of the proxy to check
    /// @return _is true if the address is a proxy address, false otherwise
    function isProxy(address _addr)
        external
        view
        returns (bool _is);

    /// @notice get count of proxies
    /// @return _allCount the number of proxies
    function allProxiesCount()
        external
        view
        returns (uint256 _allCount);

    /// @notice get the address of a proxy at a given index
    /// @param _index the index of the proxy to get
    /// @return _proxy the address of the proxy at the given index
    function proxyAt(uint256 _index)
        external
        view
        returns (address _proxy);

}
