// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ClonesUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./IERC165Upgradeable.sol";

import "./IRoleAuthority.sol";
import "./IDecaCollection.sol";
import "./IMetadataResolver.sol";
import "./IDecaCollectionFactory.sol";
import "./Errors.sol";

/**
 * @title A factory to create Deca ERC721 collections.
 * @notice Call this factory to create a DecaCollection.
 * @author 0x-jj, j6i
 */
contract DecaCollectionFactory is Initializable, IDecaCollectionFactory, UUPSUpgradeable {
  using ClonesUpgradeable for address;
  using StringsUpgradeable for uint32;

  /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice The address of the RoleAuthority used to determine whether an address has some admin role.
   */

  IRoleAuthority public immutable roleAuthority;

  /**
   * @notice The address of the DecaCollection implementation.
   */
  address public decaCollectionImplementation;

  /**
   * @notice The current version of the DecaCollection implementation.
   */
  uint256 public decaCollectionImplementationVersion;

  /**
   * @notice The address of the contract that resolves the metadata URIs for tokens.
   */

  IMetadataResolver public metadataResolver;

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Constructor only runs once, not when upgraded, so the roleAuthority is not updateable.
   * @dev Cannot be set in the initializer because roleAuthority is immutable.
   * @param _roleAuthority The address of the contract that determines whether an address has admin roles.
   */
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(address _roleAuthority) {
    roleAuthority = IRoleAuthority(_roleAuthority);
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Initializer called after contract creation.
   * @dev Can only be called once.
   * @param _decaCollectionImplementation The address of the contract with the DecaCollection implementation.
   * @param _metadataResolver The address of the contract that resolves the metadata URIs for tokens.
   */
  function initialize(address _decaCollectionImplementation, address _metadataResolver) external initializer {
    if (!roleAuthority.isOperator(msg.sender)) revert NotOperator();

    __UUPSUpgradeable_init();
    decaCollectionImplementation = _decaCollectionImplementation;
    metadataResolver = IMetadataResolver(_metadataResolver);
    decaCollectionImplementationVersion = 1;
  }

  /**
   * @notice Updates the DecaCollection implementation.
   * @dev Existing collections created by this factory are not impacted
   * @param _decaCollectionImplementation The address of the contract with the new DecaCollection implementation.
   * @param expectedInterfaceId The interface id expected to be returned by the new implementation.
   */
  function updateDecaCollectionImplementation(
    address _decaCollectionImplementation,
    bytes4 expectedInterfaceId
  ) external {
    if (!roleAuthority.isOperator(msg.sender)) revert NotOperator();
    if (!IERC165Upgradeable(_decaCollectionImplementation).supportsInterface(expectedInterfaceId))
      revert InterfaceUnsupported();

    decaCollectionImplementation = _decaCollectionImplementation;
    decaCollectionImplementationVersion++;
    emit DecaCollectionImplementationUpdated(_decaCollectionImplementation, decaCollectionImplementationVersion);
  }

  /**
   * @notice Create a new collection contract.
   * @dev The nonce must be unique for the msg.sender, otherwise this call will revert.
   * @param params CreateDecaCollectionParams struct
   * @return collection The address of the newly created collection contract.
   */
  function createDecaCollection(CreateDecaCollectionParams memory params) external returns (address) {
    if (address(0) == params.creator) revert CreatorCannotBeTheZeroAddress();
    if (!roleAuthority.is721Minter(msg.sender)) revert OnlyMinter();

    address createdProxy = decaCollectionImplementation.cloneDeterministic(_getSalt(params.creator, params.nonce));

    IDecaCollection(payable(createdProxy)).initialize(
      address(this),
      params.creator,
      address(roleAuthority),
      params.collectionName,
      params.collectionSymbol,
      params.recipients
    );

    emit DecaCollectionCreated(createdProxy, params.creator, params.collectionName);
    return createdProxy;
  }

  /**
   * @notice Update the metadata resolver contract which provides metadata for all DecaCollections
   * @param metadataResolver_ The address of the new metadata resolver contract.
   */
  function updateMetadataResolver(address metadataResolver_) external {
    if (!roleAuthority.isOperator(msg.sender)) revert NotOperator();
    metadataResolver = IMetadataResolver(metadataResolver_);
    emit MetadataResolverUpdated(metadataResolver_);
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the address of an DecaCollection given the creator and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the collection contract that would be created by this nonce.
   */
  function predictDecaCollectionAddress(address creator, uint96 nonce) external view returns (address) {
    address collection = decaCollectionImplementation.predictDeterministicAddress(_getSalt(creator, nonce));
    return collection;
  }

  /*//////////////////////////////////////////////////////////////
                                 PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the token URI for a given token
   * @param contractAddress the contract address of the token
   * @param tokenId the token id of the token
   */
  function tokenUri(address contractAddress, uint256 tokenId) public view returns (string memory) {
    return metadataResolver.tokenUri(contractAddress, tokenId);
  }

  /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev This is called as part of the UUPS upgrade process to ensure the upgrade is correctly permissioned
   */
  function _authorizeUpgrade(address) internal view override {
    if (!roleAuthority.isOperator(msg.sender)) revert NotOperator();
  }

  /*//////////////////////////////////////////////////////////////
                                 PRIVATE
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Salt is address + nonce packed.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return salt The salt used to create the collection.
   */
  function _getSalt(address creator, uint96 nonce) private pure returns (bytes32) {
    return bytes32((uint256(uint160(creator)) << 96) | uint256(nonce));
  }
}
