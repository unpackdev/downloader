// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICegaEntry.sol";

interface IAddressManager {
    /**
     * @dev Emitted when a new CegaEntry is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationParams The params of the implementation update
     */
    event CegaEntryCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        ICegaEntry.ProxyImplementation[] indexed implementationParams
    );

    /**
     * @dev Emitted when the CegaEntry is updated.
     * @param implementationParams The old address of the CegaEntry
     * @param _init The new address to call upon upgrade
     * @param _calldata The calldata input for the call
     */
    event CegaEntryUpdated(
        ICegaEntry.ProxyImplementation[] indexed implementationParams,
        address _init,
        bytes _calldata
    );

    /**
     * @dev Emitted when a new address is set
     * @param id The identifier of the proxy
     * @param oldAddress The previous address assoicated with the id
     * @param newAddress The new address set to the id
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    event AssetProxyUpdated(address asset, address proxy);

    function getCegaOracle() external view returns (address);

    function getCegaEntry() external view returns (address);

    function getTradeWinnerNFT() external view returns (address);

    function getACLManager() external view returns (address);

    function getRedepositManager() external view returns (address);

    function getCegaFeeReceiver() external view returns (address);

    function getAddress(bytes32 id) external view returns (address);

    function getAssetWrappingProxy(
        address asset
    ) external view returns (address);

    function setAddress(bytes32 id, address newAddress) external;

    function setAssetWrappingProxy(address asset, address proxy) external;

    function updateCegaEntryImpl(
        ICegaEntry.ProxyImplementation[] calldata implementationParams,
        address _init,
        bytes calldata _calldata
    ) external;
}
