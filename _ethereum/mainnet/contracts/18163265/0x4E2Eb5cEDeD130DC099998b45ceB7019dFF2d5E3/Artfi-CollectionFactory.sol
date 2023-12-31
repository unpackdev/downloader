// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Proxy.sol";
import "./Initializable.sol";
import "./Artfi-CollectionProxy.sol";
import "./Artfi-Collection.sol";


/** @title Collection Factory contract
 * @dev Factory contract for collection contract.
 */

contract CollectionFactory is Initializable {
  error GeneralError(string errorCode);
  address private _artfiMarketplace;
  address private _admin;
  uint256 private _version;

  event eCollectionContractCreated(address proxyContract);

  event eUpdateMarketplace(address artfiMarketplace_);

  modifier onlyAdmin() {
    if (msg.sender != _admin) revert GeneralError("AF:101");
    _;
  }

  /** @notice Initializes the contract by setting the address of artfi Marketplace.
   * @dev used instead of constructor.
   * @param artfiMarketplace_ address of artfi Marketplace.
   */
  function initialize(address artfiMarketplace_) external initializer {
    if(artfiMarketplace_ == address(0)) revert GeneralError("AF:205");
    _artfiMarketplace = artfiMarketplace_;
    _admin = msg.sender;
    _version = 2;
  }

  /** @notice updates the address of marketplace contract.
   * @param  artfiMarketplace_ address of artfi Marketplace.
   */
  function updateMarketplaceaddress(
    address artfiMarketplace_
  ) external onlyAdmin {
    if(artfiMarketplace_ == address(0)) revert GeneralError("AF:205");
    _artfiMarketplace = artfiMarketplace_;

    emit eUpdateMarketplace(artfiMarketplace_);

  }

  /** @notice deploys collection contract and proxy contract.
   *@dev deploys collection contract and proxy contract by creating an instance of both.
   *@param collectionName_ The name of nft created.
   *@param baseURI_ baseUri of token.
   *@param description_ description for collection.
   *@param imageURI_ URI of the image for collection.
   *@param artfiRoyaltyContract_ addresss of royalty contract.
   *@param maxBatchSize_ maximum nunber the user can mint.
   *@param collectionSize_ number of NFTs allowed in the collection.
   */
  function createNewCollection(
    string memory collectionName_,
    string memory baseURI_,
    string memory description_,
    string memory imageURI_,
    address _owner,
    address artfiRoyaltyContract_,
    uint32 maxBatchSize_,
    uint32 collectionSize_
  ) external {
    ArtfiCollectionV2 collectionV2 = new ArtfiCollectionV2();
    ArtfiProxy collectionProxy = new ArtfiProxy(
      address(collectionV2),
      _admin,
      abi.encodeWithSelector(
        ArtfiCollectionV2(address(0)).initialize.selector,
        _version,
        collectionName_,
        baseURI_,
        description_,
        imageURI_,
        _owner,
        _admin,
        _artfiMarketplace,
        artfiRoyaltyContract_,
        maxBatchSize_,
        collectionSize_
      )
    );

    emit eCollectionContractCreated(address(collectionProxy));
  }
}
