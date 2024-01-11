//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Base64.sol";
import "./Strings.sol";

contract AmbassadorNFT is ERC721Enumerable {
  using Base64 for *;
  using Strings for uint256;

  struct Base {
    string image; // base image
    address collection; // Drops dToken
  }

  /// @dev emit when new collection registered
  event CollectionRegistered(address collection, string name);

  /// @dev emit when base gets added or updated
  event BaseUpdated(uint256 index, Base base);

  /// @dev emit when base/votingWeight for ambassador being set
  event AmbassadorUpdated(uint256 tokenId, uint256 base, uint256 weight);

  uint128 public constant DEFAULT_WEIGHT = 3_000 * 1e18; // 3k

  string public constant DESCRIPTION =
    'The Ambassador NFT is a non-transferable token exclusively available to Drops DAO ambassadors. Each NFT provides veDOP voting power which is used in DAO governance process.';

  bool public initialized;

  /// @dev collection name mapped by collection address
  mapping(address => string) public collectionNames;

  /// @dev array of Bases
  Base[] public bases;

  /// @dev tokenId => base info
  /// top 128 bit = base_index
  /// bottom 128 bit = weight
  mapping(uint256 => uint256) public info;

  /// @dev baseURI
  string private baseURI;

  function initialize(string memory _baseURI) external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;

    name = 'Drops DAO Ambassadors';
    symbol = 'DROPSAMB';

    baseURI = _baseURI;
  }

  /// @dev register collection name
  /// @param collection collection address
  /// @param name collection name
  function registerCollection(address collection, string calldata name) external onlyOwner {
    collectionNames[collection] = name;

    emit CollectionRegistered(collection, name);
  }

  /// @dev add new base
  /// @param image base image
  /// @param collection base collection
  function addBase(string calldata image, address collection) external onlyOwner {
    require(bytes(collectionNames[collection]).length > 0, 'addBase: Invalid collection');
    Base memory base = Base(image, collection);
    emit BaseUpdated(bases.length, base);
    bases.push(base);
  }

  /// @dev update base
  /// @param index base index
  /// @param image base image
  /// @param collection base collection
  function updateBase(
    uint256 index,
    string calldata image,
    address collection
  ) external onlyOwner {
    require(index < bases.length, 'updateBase: Invalid index');

    Base storage base = bases[index];
    base.image = image;
    base.collection = collection;

    emit BaseUpdated(index, base);
  }

  /// @dev return total number of bases
  /// @return uint256
  function totalBases() external view returns (uint256) {
    return bases.length;
  }

  /// @dev mint new NFT
  /// @param tokenId ambassador id
  /// @param to ambassador wallet
  /// @param base ambassador index
  function mintInternal(
    uint256 tokenId,
    address to,
    uint256 base
  ) internal {
    require(to != address(0), 'mint: Invalid to');
    require(base < bases.length, 'mint: Invalid base');

    // Mint new token
    info[tokenId] = (base << 128) | DEFAULT_WEIGHT;
    _mint(to, tokenId);

    emit AmbassadorUpdated(tokenId, base, DEFAULT_WEIGHT);
  }

  /// @dev mint new NFT
  /// @param tokenId ambassador id
  /// @param to ambassador wallet
  /// @param base ambassador index
  function mint(
    uint256 tokenId,
    address to,
    uint256 base
  ) public onlyOwner {
    mintInternal(tokenId, to, base);
  }

  /// @dev mint new NFTs
  /// @param tokenIds ambassador ids
  /// @param wallets ambassador wallets
  /// @param baseIndexes ambassador bases
  function mints(
    uint256[] calldata tokenIds,
    address[] calldata wallets,
    uint256[] calldata baseIndexes
  ) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      mintInternal(tokenIds[i], wallets[i], baseIndexes[i]);
    }
  }

  /// @dev update weight
  /// @param tokenId ambassador id
  /// @param weight ambassador weight
  function updateAmbWeight(uint256 tokenId, uint256 weight) external onlyOwner {
    require(ownerOf[tokenId] != address(0), 'updateWeight: Non-existent token');

    uint256 base = info[tokenId] >> 128;
    info[tokenId] = (base << 128) | weight;

    emit AmbassadorUpdated(tokenId, base, weight);
  }

  /// @dev update base
  /// @param tokenId ambassador id
  /// @param base ambassador base
  function updateAmbBase(uint256 tokenId, uint256 base) external onlyOwner {
    require(ownerOf[tokenId] != address(0), 'updateBase: Non-existent token');

    uint128 weight = uint128(info[tokenId]);
    info[tokenId] = (base << 128) | weight;

    emit AmbassadorUpdated(tokenId, base, weight);
  }

  /// @dev get ambassador
  /// @param tokenId ambassador id
  /// @return weight ambassador weight
  /// @return image ambassador image
  /// @return collection ambassador collection
  function getAmbassador(uint256 tokenId)
    public
    view
    returns (
      uint256 weight,
      string memory image,
      address collection
    )
  {
    require(ownerOf[tokenId] != address(0), 'getAmbassador: Non-existent token');

    uint256 base = info[tokenId];
    weight = uint128(base);
    base = base >> 128;
    image = bases[base].image;
    collection = bases[base].collection;
  }

  /// @dev burns FNT
  /// Only the owner can do this action
  /// @param tokenId tokenID of NFT to be burnt
  function burn(uint256 tokenId) external onlyOwner {
    _burn(tokenId);
  }

  /// @dev return tokenURI per tokenId
  /// @return tokenURI string
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(ownerOf[tokenId] != address(0), 'tokenURI: Non-existent token');

    (uint256 weight, string memory image, address collection) = getAmbassador(tokenId);

    string memory attributes = string(
      abi.encodePacked(
        '[{"trait_type":"Collection","value":"',
        collectionNames[collection],
        '"},{"display_type":"number","trait_type":"veDOP","value":',
        (weight / 1e18).toString(),
        '}]'
      )
    );

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              string(abi.encodePacked('Ambassador', ' #', tokenId.toString())),
              '","description":"',
              DESCRIPTION,
              '","image":"',
              string(abi.encodePacked(baseURI, image)),
              '","attributes":',
              attributes,
              '}'
            )
          )
        )
      );
  }

  /// @dev check if caller is owner
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override onlyOwner {
    // one wallet cannot hold more than 1 NFT
    require(balanceOf[to] == 0, 'transfer: Already an ambassador');
    ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
  }

  /// @dev See {IERC721-transferFrom}.
  /// clear approve or owner logic since admin will transfer NFTs without permissions from owner
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    // admin will transfer NFTs without approve
    _transfer(from, to, tokenId);
  }
}
