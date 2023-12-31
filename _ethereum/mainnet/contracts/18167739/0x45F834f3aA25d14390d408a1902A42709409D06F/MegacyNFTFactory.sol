// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AddressUpgradeable.sol";
import "./Clones.sol";
import "./Strings.sol";
// import "./Create2.sol";
// import "./Ownable.sol";

import "./MegacyNFTCollection.sol";
import "./TokenOwnershipRegister.sol";

import "./ICollectionContractInitializer.sol";
import "./ICollectionFactory.sol";
import "./IProxyCall.sol";
import "./IRoles.sol";

contract MegacyNFTFactory is ICollectionFactory, Ownable {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using Clones for address;
  using Strings for uint256;

    address tokenOwnershipRegisterAddress;

    event CollectionDeployed(address _creatorAddress, address _contractAddress);

    /**
     * @notice The contract address which manages common roles.
     * @dev Used by the collections for a shared operator definition.
     */
    IRoles public rolesContract;

    /**
     * @notice The address of the template all new collections will leverage.
     */
    address public implementation;

    /**
     * @notice The address of the proxy call contract implementation.
     * @dev Used by the collections to safely call another contract with arbitrary call data.
     */
    IProxyCall public proxyCallContract;

    /**
     * @notice The implementation version new collections will use.
     * @dev This is auto-incremented each time the implementation is changed.
     */
    uint256 public version;

    modifier onlyAdmin() {
        require(rolesContract.isAdmin(msg.sender), "Caller does not have the Admin role");
        _;
    }

    modifier onlyContract() {
        require(rolesContract.isAdmin(msg.sender), "Caller does not have the Admin role");
        _;
    }

    constructor(address _ownershipRegisterAddress) {
        tokenOwnershipRegisterAddress = _ownershipRegisterAddress;
    }

    /**
     * @notice Defines requirements for the collection factory at deployment time.
     * @param _proxyCallContract The address of the proxy call contract implementation.
     * @param _rolesContract The address of the contract defining roles for collections to use.
     */
    // constructor(address _proxyCallContract, address _rolesContract) {
    //     _updateRolesContract(_rolesContract);
    //     _updateProxyCallContract(_proxyCallContract);
    // }

    /**
     * @notice Allows Musee to change the collection implementation used for future collections.
     * This call will auto-increment the version.
     * Existing collections are not impacted.
     * @param _implementation The new collection implementation address.
     */
    function adminUpdateImplementation(address _implementation) external onlyAdmin {
        _updateImplementation(_implementation);
    }

    /**
     * @notice Allows Musee to change the proxy call contract address.
     * @param _proxyCallContract The new proxy call contract address.
     */
    function adminUpdateProxyCallContract(address _proxyCallContract) external onlyAdmin {
        _updateProxyCallContract(_proxyCallContract);
    }

    /**
     * @notice Allows Musee to change the admin role contract address.
     * @param _rolesContract The new admin role contract address.
     */
    function adminUpdateRolesContract(address _rolesContract) external onlyAdmin {
        _updateRolesContract(_rolesContract);
    }

    /**
    @notice Function used to receive ether
    @dev  Emits "LogDepositReceived" event | Ether send to this contract for
    no reason will be credited to the contract owner, and the deposit logged,
    */
    receive() external payable{
        payable (owner()).transfer(msg.value);
    }

    /**
    @notice Factory function used to create a NFT collection
    @dev Emits "CollectionDeployed" event
    */
    function createBlankNftCollection(string calldata _collectionName, string calldata _collectionSymbol, string calldata _collectionUri) external returns (address collectionAddress) {
        MegacyNFTCollection newCollect = new MegacyNFTCollection(address(this), _collectionName, _collectionSymbol, _collectionUri, msg.sender);
        collectionAddress = address(newCollect);
        TokenOwnershipRegister(tokenOwnershipRegisterAddress).registerCollection(collectionAddress);
        emit CollectionDeployed(msg.sender, collectionAddress);
    }

    function recordMint(address _collection, address _owner, uint _tokenId) external {
        TokenOwnershipRegister(tokenOwnershipRegisterAddress).recordMint(_collection, _owner, _tokenId);
    }

    function recordTransfer(address _collection, address _from, address _to, uint _tokenId) external {
        TokenOwnershipRegister(tokenOwnershipRegisterAddress).recordTransfer(_collection, _from, _to, _tokenId);
    }

    function _updateRolesContract(address _rolesContract) private {
        require(_rolesContract.isContract(), "not a contract");
        rolesContract = IRoles(_rolesContract);
        // emit RolesContractUpdated(_rolesContract);
    }
    
    /**
     * @notice Returns the address of a collection given the current implementation version, creator, and nonce.
     * This will return the same address whether the collection has already been created or not.
     * @param creator The creator of the collection.
     * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
     * @return collectionAddress The address of the collection contract that would be created by this nonce.
     */
    function predictCollectionAddress(address creator, uint256 nonce) external view returns (address collectionAddress) {
        collectionAddress = implementation.predictDeterministicAddress(_getSalt(creator, nonce));
    }

    function _getSalt(address creator, uint256 nonce) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(creator, nonce));
    }

    /**
     * @dev Updates the implementation address, increments the version, and initializes the template.
     * Since the template is initialized when set, implementations cannot be re-used.
     * To downgrade the implementation, deploy the same bytecode again and then update to that.
     */
    function _updateImplementation(address _implementation) private {
        require(_implementation.isContract(), "not a contract");
        implementation = _implementation;
        unchecked {
        // Version cannot overflow 256 bits.
        version++;
        }
        // The implementation is initialized when assigned so that others may not claim it as their own.
        ICollectionContractInitializer(_implementation).initialize(
            payable(address(rolesContract)),
            string(abi.encodePacked("MCY Collection Template v", version.toString())),
            string(abi.encodePacked("FCTv", version.toString()))
            );
        // emit ImplementationUpdated(_implementation, version);
    }

    function _updateProxyCallContract(address _proxyCallContract) private {
        require(_proxyCallContract.isContract(), "not a contract");
        proxyCallContract = IProxyCall(_proxyCallContract);
    }
}