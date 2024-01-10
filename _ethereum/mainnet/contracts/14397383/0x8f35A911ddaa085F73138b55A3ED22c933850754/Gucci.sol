// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./StringsUpgradeable.sol";

interface ERC721Interface {
  function ownerOf(uint256 _tokenId) external view returns (address);
}

interface ERC1155Interface {
  function balanceOf(address owner, uint256 tokenId) external view returns (uint256);
}

interface MintPassInterface {
  function burn(address _owner) external returns (bool);
}

interface WolfGameStakingInterface {
  function tokenStakes(uint256 tokenId) external view returns (uint16 pack, uint80 lastUpdated, address owner);
}

contract Gucci is
  ERC721Upgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  AccessControlEnumerableUpgradeable,
  ReentrancyGuardUpgradeable
{
  address internal _mintPassContractAddress;
  string internal _baseMetadataURI;
  uint256 public constant MINT_PASS_ID = 0;
  mapping(uint256 => address) internal erc721ContractAddresses;
  mapping(uint256 => address) internal erc1155ContractAddresses;

  event SuitMinted(address minter, uint256 id, uint256 parentContractIndex, uint256 parentTokenId, uint256 suitId);

  // contract index => (token id => (suit id => used))
  mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) mintedSuit;

  using StringsUpgradeable for uint256;

  address internal _wolfGameContractAddress;
  address internal _wolfGameStakingContractAddress;

  uint256 private mintStartTime;
  uint256 private mintEndTime;

  function initialize() external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __AccessControl_init();
    __ERC721_init("Gucci", "GUCCI");

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function version() external pure virtual returns (string memory) {
    return "1.0.0";
  }

  function supportsInterface(
  bytes4 interfaceId
  )
    public view virtual override(AccessControlEnumerableUpgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return interfaceId == type(IERC721Upgradeable).interfaceId
    || super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId)
  public
  view
  virtual
  override
  returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "ipfs://QmQfHT5n7t12BCJuhEHk2q61pnFxXsRYFQ4WRFWaGRGokk";
  }

  function setBaseURI(string calldata baseURI)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _baseMetadataURI = baseURI;
  }

  function _baseURI()
  internal
  view
  override
  returns (string memory)
  {
    return _baseMetadataURI;
  }

  function getErc721ContractAddress(uint16 index)
  external
  view
  onlyRole(DEFAULT_ADMIN_ROLE)
  returns (address)
  {
    return erc721ContractAddresses[index];
  }

  function _setErc721ContractAddress(uint16 index, address contractAddress)
  internal
  {
    erc721ContractAddresses[index] = contractAddress;
  }

  function setErc721ContractAddresses(
    uint16[] calldata indexes,
    address[] calldata contractAddresses
  )
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(indexes.length == contractAddresses.length, "Mismatched amount of indexes and contracts");

    for (uint i = 0; i < indexes.length; i++) {
      _setErc721ContractAddress(indexes[i], contractAddresses[i]);
    }
  }

  function getErc1155ContractAddress(uint16 index)
  external
  view
  onlyRole(DEFAULT_ADMIN_ROLE)
  returns (address)
  {
    return erc1155ContractAddresses[index];
  }

  function setErc1155ContractAddress(uint16 index, address contractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    erc1155ContractAddresses[index] = contractAddress;
  }

  function getMintPassContractAddress()
  external
  view
  onlyRole(DEFAULT_ADMIN_ROLE)
  returns (address)
  {
    return _mintPassContractAddress;
  }

  function setMintPassContractAddress(address mintPassContractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _mintPassContractAddress = mintPassContractAddress;
  }

  function getWolfGameContractAddress()
  external
  view
  onlyRole(DEFAULT_ADMIN_ROLE)
  returns (address)
  {
    return _wolfGameContractAddress;
  }

  function setWolfGameContractAddress(address wolfGameContractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _wolfGameContractAddress = wolfGameContractAddress;
  }

  function getWolfGameStakingContractAddress()
  external
  view
  onlyRole(DEFAULT_ADMIN_ROLE)
  returns (address)
  {
    return _wolfGameStakingContractAddress;
  }

  function setWolfGameStakingContractAddress(address wolfGameStakingContractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _wolfGameStakingContractAddress = wolfGameStakingContractAddress;
  }

  function _ownsParentToken(
    address wallet,
    uint256 parentTokenId,
    uint256 parentContractIndex
  )
  internal
  view
  returns (bool)
  {
    address erc721ContractAddress = erc721ContractAddresses[parentContractIndex];
    address erc1155ContractAddress = erc1155ContractAddresses[parentContractIndex];

    require(erc721ContractAddress != address(0) || erc1155ContractAddress != address(0), "No parent contract found");
    require((erc721ContractAddress != address(0) && erc1155ContractAddress != address(0)) == false, "Multiple contracts found");

    if (erc721ContractAddress != address(0)) {
      /**
       * Wolf Game can also prove ownership via staking.
       */
      if (erc721ContractAddress == _wolfGameContractAddress) {
        WolfGameStakingInterface wolfGameStakingContractInstance = WolfGameStakingInterface(_wolfGameStakingContractAddress);

        uint16 pack;
        uint80 lastUpdated;
        address owner;

        (pack, lastUpdated, owner) = wolfGameStakingContractInstance.tokenStakes(parentTokenId);

        if (pack != 0) {
          return wallet == owner;
        }
      }

      ERC721Interface Erc721ContractInstance = ERC721Interface(erc721ContractAddress);

      return wallet == Erc721ContractInstance.ownerOf(parentTokenId);
    }

    if (erc1155ContractAddress != address(0)) {
      ERC1155Interface Erc1155ContractInstance = ERC1155Interface(erc1155ContractAddress);

      return Erc1155ContractInstance.balanceOf(wallet, parentTokenId) != 0;
    }

    return false;
  }

  function setMintTimes(uint256 _mintStartTime, uint256 _mintEndTime)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    mintStartTime = _mintStartTime;
    mintEndTime = _mintEndTime;
  }

  function mintTokens(
    uint256[] calldata tokenIds
  )
  external
  {
    require(block.timestamp >= mintStartTime, "Minting hasn't started yet");
    require(block.timestamp <= mintEndTime, "Minting has ended");

    for (uint i = 0; i < tokenIds.length; i++) {
      _mint(tokenIds[i]);
    }
  }

  function _mint(
    uint256 tokenId
  )
  internal
  {
    require(_mintPassContractAddress != address(0), "Mint pass contract not set");
    MintPassInterface MintPassContractInstance = MintPassInterface(_mintPassContractAddress);

    uint64 parentContractIndex = uint64((tokenId & 0xFFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 128);
    uint64 parentTokenId = uint64((tokenId & 0xFFFFFFFFFFFFFFFF0000000000000000) >> 64);
    uint64 suitId = uint64((tokenId & 0xFFFFFFFFFFFFFFFF));

    require(_ownsParentToken(_msgSender(), parentTokenId, parentContractIndex), "You can only mint if you own the original NFT");
    require(mintedSuit[parentContractIndex][parentTokenId][suitId] == false, "Already minted a suit for the parent token");

    bool success = MintPassContractInstance.burn(_msgSender());
    require(success, "No mint pass available to use");

    _safeMint(_msgSender(), tokenId);

    mintedSuit[parentContractIndex][parentTokenId][suitId] = true;

    emit SuitMinted(_msgSender(), tokenId, parentContractIndex, parentTokenId, suitId);
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  virtual
  override
  onlyRole(DEFAULT_ADMIN_ROLE)
  {}
}
