// SPDX-License-Identifier: MIT

/**
 * Created on 2023-09-15 14:48
 * @summary:
 * @author: mauro
 */
pragma solidity ^0.8.19;

interface IPRegistry {
    /**
     * @dev Emitted when a challenge is started.
     *
     * @param networkId The network id
     * @param chainId The chain id
     * @param hub The hub
     */
    event NetworkAdded(bytes4 indexed networkId, uint32 indexed chainId, address hub);

    /**
     * @dev Returns the chain id for the given network ID
     *
     * @param networkId a network ID
     *
     * @return uint32 chain id for the given network ID
     */
    function getChainIdByNetworkId(bytes4 networkId) external view returns (uint32);

    /**
     * @dev Returns the pNetwork hub address for the given network ID
     *
     * @param networkId a network ID
     *
     * @return address pNetwork hub address on the given network ID
     */
    function getHubByNetworkId(bytes4 networkId) external view returns (address);

    /**
     * @dev Return the supported chain IDs
     * @return uint32[] the array of supported chain ids
     */
    function getSupportedChainIds() external view returns (uint32[] memory);

    /**
     * @dev Return the supported hubs
     */
    function getSupportedHubs() external view returns (address[] memory);

    /**
     * @dev Return the supported chain ID
     * @param chainId the chain id
     */
    function isChainIdSupported(uint32 chainId) external view returns (bool);

    /*
     * @dev Return true if the given network id has been registered on pNetwork
     *
     * @param networkId the network ID
     *
     * @return bool true or false
     */
    function isNetworkIdSupported(bytes4 networkId) external view returns (bool);

    /*
     * @dev Add a new entry for the map network ID => hub
     *
     * @param networkId the network ID
     * @param hub pNetwork hub contract address
     */
    function protocolAddNetwork(uint32 chainId, address hub) external;
}
