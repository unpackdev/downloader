pragma solidity >=0.8.0;
pragma abicoder v2;

import "./ERC165Storage.sol";
import "./PublicResolver.sol";
import "./PxgRegistrar.sol";

interface NFTInterface {
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface Punks {
  function punkIndexToAddress(uint256 index) external view returns (address);
}

contract PxgResolverV1 is ERC165Storage, PublicResolver {
  PxgRegistrar registrar;

  mapping(address => bool) private admin;

  constructor(
    address ens,
    address registrarAddress,
    address initialAdmin
  ) PublicResolver(ens, registrarAddress) {
    registrar = PxgRegistrar(registrarAddress);
    admin[initialAdmin] = true;
  }

  event ModifyAdmin(address adminAddr, bool value);

  modifier onlyAdmin() {
    require(admin[msg.sender], "Not admin");
    _;
  }

  function modifyAdmin(address adminAddr, bool value) public onlyAdmin {
    admin[adminAddr] = value;
    emit ModifyAdmin(adminAddr, value);
  }

  /**
   * Returns the address associated with an ENS node. Will default to owner of NFT
   * if no address has been set.
   * @param node The ENS node to query.
   * @return The associated address.
   */
  function addr(bytes32 node) public view override returns (address payable) {
    try nameWrapper.ownerOf(uint256(node)) returns (address nameOwner) {
      return payable(nameOwner);
    } catch Error(string memory) {
      // no op
    } catch (bytes memory) {
      // no op
    }
    return payable(0);
  }

  address PUNK_ADDRESS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

  struct NFT {
    address collectionAddress;
    uint256 tokenId;
    bool exists;
  }

  struct Sale {
    NFT nft;
    uint256 price;
  }

  // node to default avatar
  mapping(bytes32 => NFT) defaultAvatar;
  // node to gallery
  mapping(bytes32 => NFT[5]) gallery;

  event DefaultAvatarSet(
    bytes32 indexed node,
    address collection,
    uint256 tokenId
  );

  /**
    @notice Get the length of gallery array.
    @dev Can use length to iterate gallery items on client
    @param node The ENS node
    @return Returns the length of gallery array
   */
  function getGalleryLength(bytes32 node) public view returns (uint256) {
    return gallery[node].length;
  }

  function getGalleryItemAtIndex(bytes32 node, uint256 idx)
    public
    view
    returns (address, uint256)
  {
    if (
      !gallery[node][idx].exists ||
      !_isValidOwner(
        node,
        gallery[node][idx].collectionAddress,
        gallery[node][idx].tokenId
      )
    ) {
      return (address(0), uint256(0));
    }

    return _validateNftData(node, gallery[node][idx]);
  }

  function setManyGalleryItems(
    bytes32 node,
    address[] memory collections,
    uint256[] memory ids,
    uint256[] memory idx
  ) public {
    require(collections.length == ids.length);
    require(collections.length == idx.length);
    require(collections.length <= 5);

    for (uint256 i; i < collections.length; i++) {
      setGalleryItem(node, collections[i], ids[i], idx[i]);
    }
  }

  /**
    @notice Allows a node owner to set a gallery NFT.
    @dev Verifies that the owner of the ENS nodes owns the NFT. 
    @param node The ENS node
    @param collectionAddress The NFT collection address
    @param tokenId The NFT ID
    @param idx The index at which to set the gallery item
   */
  function setGalleryItem(
    bytes32 node,
    address collectionAddress,
    uint256 tokenId,
    uint256 idx
  ) public {
    require(idx <= 4, "Index out of bounds");
    require(
      _isValidOwner(node, collectionAddress, tokenId),
      "Not a valid owner"
    );
    require(isAuthorised(node), "Not authorized");
    gallery[node][idx].collectionAddress = collectionAddress;
    gallery[node][idx].tokenId = tokenId;
    gallery[node][idx].exists = true;
  }

  /**
    @notice Removes an NFT from an owners gallery.
    @param node ENS node
    @param collectionAddress NFT collection address
    @param tokenId NFT ID
    @param idx Index of gallery item to remove
   */
  function removeGalleryItem(
    bytes32 node,
    address collectionAddress,
    uint256 tokenId,
    uint256 idx
  ) public {
    require(idx <= 4, "Index out of bounds");
    require(
      _isValidOwner(node, collectionAddress, tokenId),
      "Not a valid owner"
    );
    require(isAuthorised(node), "Not authorized");
    require(gallery[node][idx].exists == true, "Index does not exist");
    // remove if last index of array
    if (idx == gallery[node].length - 1) {
      delete gallery[node][gallery[node].length - 1];
    } else {
      // Swap idx item with last item and remove last item
      gallery[node][idx] = gallery[node][gallery[node].length - 1];
      delete gallery[node][gallery[node].length - 1];
    }
  }

  /**
    @notice Checks to see if node owner is the owner of the given NFT.
    @param node The ENS node
    @param collection The NFT collection address
    @param tokenId The NFT ID
   */
  function _isValidOwner(
    bytes32 node,
    address collection,
    uint256 tokenId
  ) internal view returns (bool) {
    if (collection == PUNK_ADDRESS) {
      return Punks(PUNK_ADDRESS).punkIndexToAddress(tokenId) == addr(node);
    } else {
      try NFTInterface(collection).ownerOf(tokenId) returns (
        address ownerAddr
      ) {
        return ownerAddr == addr(node);
      } catch Error(
        string memory /*reason*/
      ) {
        return false;
      } catch Panic(
        uint256 /*errorCode*/
      ) {
        return false;
      } catch (
        bytes memory /*lowLevelData*/
      ) {
        return false;
      }
    }
  }

  /**
    @notice Validates that the node owner is the owner of the NFT
    @dev May return address 0 uint 0
    @param node ENS node
    @param nft NFT struct
    @return Returns the NFT address and ID 
   */
  function _validateNftData(bytes32 node, NFT memory nft)
    internal
    view
    returns (address, uint256)
  {
    if (nft.exists && _isValidOwner(node, nft.collectionAddress, nft.tokenId)) {
      return (nft.collectionAddress, nft.tokenId);
    }
    return (address(0), uint256(0));
  }

  /**
    @notice Get the default avatar.
    @dev May return address 0 and uint 0 if not set, or now longer owner
    @param node ENS node
    @return Returns the address of the collection and NFT token ID
   */
  function getDefaultAvatar(bytes32 node)
    public
    view
    returns (address, uint256)
  {
    NFT memory nft = defaultAvatar[node];
    return _validateNftData(node, nft);
  }

  /**
    @notice Sets the default NFT avatar for a given node. 
    @dev Emits event
    @param node The ENS node
    @param collection The NFT collection address
    @param tokenId The NFT ID
   */
  function setDefaultAvatar(
    bytes32 node,
    address collection,
    uint256 tokenId
  ) public {
    require(isAuthorised(node), "Unauthorized");
    require(
      registrar.supportsCollection(collection),
      "Collection not supported"
    );
    require(_isValidOwner(node, collection, tokenId), "Not valid owner");
    defaultAvatar[node] = NFT(collection, tokenId, true);
    emit DefaultAvatarSet(node, collection, tokenId);
  }

  function supportsInterface(bytes4 interfaceID)
    public
    pure
    virtual
    override(ERC165Storage, PublicResolver)
    returns (bool)
  {
    return super.supportsInterface(interfaceID);
  }
}
