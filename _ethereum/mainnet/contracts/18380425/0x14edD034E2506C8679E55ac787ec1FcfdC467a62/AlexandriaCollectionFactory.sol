// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* 
      ___                     ___         ___         ___         ___        _____        ___                   ___     
     /  /\                   /  /\       /__/|       /  /\       /__/\      /  /::\      /  /\      ___        /  /\    
    /  /::\                 /  /:/_     |  |:|      /  /::\      \  \:\    /  /:/\:\    /  /::\    /  /\      /  /::\   
   /  /:/\:\  ___     ___  /  /:/ /\    |  |:|     /  /:/\:\      \  \:\  /  /:/  \:\  /  /:/\:\  /  /:/     /  /:/\:\  
  /  /:/~/::\/__/\   /  /\/  /:/ /:/_ __|__|:|    /  /:/~/::\ _____\__\:\/__/:/ \__\:|/  /:/~/:/ /__/::\    /  /:/~/::\ 
 /__/:/ /:/\:\  \:\ /  /:/__/:/ /:/ //__/::::\___/__/:/ /:/\:/__/::::::::\  \:\ /  /:/__/:/ /:/__\__\/\:\__/__/:/ /:/\:\
 \  \:\/:/__\/\  \:\  /:/\  \:\/:/ /:/  ~\~~\::::\  \:\/:/__\\  \:\~~\~~\/\  \:\  /:/\  \:\/:::::/  \  \:\/\  \:\/:/__\/
  \  \::/      \  \:\/:/  \  \::/ /:/    |~~|:|~~ \  \::/     \  \:\  ~~~  \  \:\/:/  \  \::/~~~~    \__\::/\  \::/     
   \  \:\       \  \::/    \  \:\/:/     |  |:|    \  \:\      \  \:\       \  \::/    \  \:\        /__/:/  \  \:\     
    \  \:\       \__\/      \  \::/      |  |:|     \  \:\      \  \:\       \__\/      \  \:\       \__\/    \  \:\    
     \__\/                   \__\/       |__|/       \__\/       \__\/                   \__\/                 \__\/    
 */

import "./Pausable.sol";
import "./Ownable2Step.sol";
import "./ERC1967Proxy.sol";
import "./AlexandriaCollection.sol";
import "./IVersionedContract.sol";

/**
 * @dev This factory creates Alexandria collections deployed as ERC1967 proxies.
 *      For more info or to publish your own Alexandria collection, visit alexandrialabs.xyz.
 */
/// @custom:security-contact tech@alexandrialabs.xyz
contract AlexandriaCollectionFactory is Pausable, Ownable2Step {
    address public immutable PROXY_IMPLEMENTATION_ADDRESS;

    // Event to indicate a new factory has been deployed.
    event FactoryDeployed(address indexed factoryAddress, address proxyImplementationAddress);

    // Event to indicate the factory has deployed a new collection.
    event CollectionDeployed(address indexed collectionAddress, string collectionID);

    /**
     * @dev Initializes the factory with the implementation contract address for the ERC1967 proxies.
     *
     * @param proxyImplementationAddress_ The address to be used as the proxy implementation address
     * for the AlexandriaCollection contract. This value is set at deployment and is immutable thereafter.
     */
    constructor(address proxyImplementationAddress_) {
        PROXY_IMPLEMENTATION_ADDRESS = proxyImplementationAddress_;
        emit FactoryDeployed(address(this), PROXY_IMPLEMENTATION_ADDRESS);
    }

    /**
     * @dev Deploys a new Alexandria collection as an ERC1967 proxy.
     */
    function deployCollection(
        string memory collectionID,
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory contractURI,
        AlexandriaCollection.CollectionParameters memory collectionParameters
    ) external whenNotPaused {
        bytes memory initCalldata = abi.encodeCall(
            AlexandriaCollection.initialize,
            (
                name,
                symbol,
                baseTokenURI,
                contractURI,
                collectionParameters,
                msg.sender, // message sender is publisher
                owner() // factory owner is platformAdmin
            )
        );
        ERC1967Proxy collectionProxy = new ERC1967Proxy(PROXY_IMPLEMENTATION_ADDRESS, initCalldata);

        emit CollectionDeployed(address(collectionProxy), collectionID);
    }

    /**
     * @dev see {Pausable-_pause}
     * Provides the ability to pause collection deployments by this factory.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}
     * Provides the ability to unpause collection deployments by this factory.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Returns the contract type of the implementation contract for the
     *      factory proxies.
     */
    function getProxyImplementationContractType() external view returns (bytes32) {
        IVersionedContract proxyImplementationContract = IVersionedContract(
            PROXY_IMPLEMENTATION_ADDRESS
        );
        return proxyImplementationContract.contractType();
    }

    /**
     * @dev Returns the contract version of the implementation contract for the
     *      factory proxies.
     */
    function getProxyImplementationContractVersion() external view returns (bytes8) {
        IVersionedContract proxyImplementationContract = IVersionedContract(
            PROXY_IMPLEMENTATION_ADDRESS
        );
        return proxyImplementationContract.contractVersion();
    }
}
