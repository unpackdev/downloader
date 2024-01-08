// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC721Tradable.sol";
import "./LootBox.sol";

/**
 * @title CryptoShihTzu
 * CryptoShihTzu - a NFT contract that holds the minted CRYPTO Shih Tzus
 */
contract CryptoShihTzu is ERC721Tradable {
  using SafeMath for uint256;
  uint256[] public attributeItemsPerRarity;

  uint256 public INVERSE_BASIS_POINT = 10000;

  string public attributeListPDF = "";

  struct TokenData {
    uint256 lootBoxOptionId;
    uint256 seed;
  }

  mapping(uint256 => TokenData) public tokenIdToData;

  address public lootBoxAddress;

  constructor(
    address _proxyRegistryAddress,
    address _lootBoxAddress,
    string memory _baseTokenURI
  )
    ERC721Tradable("CryptoShihTzu", "CST", _proxyRegistryAddress, _baseTokenURI)
  {
    lootBoxAddress = _lootBoxAddress;

    // Background
    attributeItemsPerRarity.push(20);

    // Back Paws
    attributeItemsPerRarity.push(3);

    // Ears+Front Paws
    attributeItemsPerRarity.push(3);

    // Collars
    attributeItemsPerRarity.push(20);

    // Collar Accessories
    attributeItemsPerRarity.push(20);

    // Heads
    attributeItemsPerRarity.push(3);

    // Patterns
    attributeItemsPerRarity.push(50);

    // Eyes
    attributeItemsPerRarity.push(20);

    // Beards
    attributeItemsPerRarity.push(50);

    // Head Accessories
    attributeItemsPerRarity.push(20);
  }

  /**
   * @dev Only addresses from minter mapping or owner can mit
   */
  modifier onlyLootbox() {
    require(
      _msgSender() == lootBoxAddress,
      "onlyLootbox: Not Lootbox contract"
    );
    _;
  }

  /**
   * @dev Set the attribute list pdf that lists all attribute items and explains how the token data is used to generate the image
   * @param _attributeListPDF the ipfs hash of the attribute list pdf
   */
  function setAttributeListPDF(string calldata _attributeListPDF)
    public
    onlyOwner
  {
    require(bytes(attributeListPDF).length == 0, "Already set");

    attributeListPDF = _attributeListPDF;
  }

  /**
   * @dev Mint token and requests randomness for attribute generation
   * @param _to address of the future owner of the token
   */
  function mintTo(address _to, uint256 _lootBoxOptionId) public onlyLootbox {
    // mint shih tzu
    uint256 _newTokenId = _getNextTokenId();
    _mint(_to, _newTokenId);
    _incrementTokenId();

    // generate random seed
    tokenIdToData[_newTokenId] = TokenData(
      _lootBoxOptionId,
      generateRandomSeed(_newTokenId)
    );
  }

  /**
   * @dev Genereate a random seed that will be used for attribute generation
   */
  function generateRandomSeed(uint256 _tokenId)
    internal
    view
    returns (uint256)
  {
    uint256 seed = uint256(
      keccak256(
        abi.encodePacked(
          block.timestamp +
            block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
              (block.timestamp)) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
              (block.timestamp)) +
            block.number +
            _tokenId
        )
      )
    );

    return seed;
  }

  /**
   * @dev Calculate the attribute list of a token ID by it's seed
   * @param _tokenId The tokenId
   */
  function calculateAttributeList(uint256 _tokenId)
    external
    view
    returns (uint256[] memory _attributes)
  {
    require(
      tokenIdToData[_tokenId].lootBoxOptionId > 0,
      "A seed has not been generated for this tokenId"
    );

    TokenData memory _tokenData = tokenIdToData[_tokenId];

    (uint256 _totalSupply, uint16[4] memory _probabilities) = LootBox(
      lootBoxAddress
    ).getOption(_tokenData.lootBoxOptionId);

    // first split received randomness into multipe random values
    uint256 _currRandIndex = 0;
    uint256[] memory _randomValues = _expandRandomness(
      _tokenData.seed,
      attributeItemsPerRarity.length * 2
    );

    uint256[] memory _result = new uint256[](attributeItemsPerRarity.length);

    // pick item id for each attribute
    for (uint256 i = 0; i < attributeItemsPerRarity.length; i++) {
      // determine rarity
      uint16 rarityRand = uint16(
        _randomValues[_currRandIndex].mod(INVERSE_BASIS_POINT)
      );

      uint256 _itemsPerRarity = attributeItemsPerRarity[i];

      _currRandIndex++;

      // pick rarity
      for (uint256 x = 0; x < _probabilities.length; x++) {
        // id is 0-9: common, 10-19: rare etc.
        if (rarityRand <= _probabilities[x]) {
          uint256 _attrId = _randomValues[_currRandIndex].mod(
            _itemsPerRarity - 1
          ) + x * _itemsPerRarity;

          _result[i] = _attrId;
          break;
        }
      }

      _currRandIndex++;
    }

    return _result;
  }

  /**
   * @dev Turn a single randomness into n randomnesses
   * @param _randomness The randomness to expand
   * @param _n The randomness to expand
   */
  function _expandRandomness(uint256 _randomness, uint256 _n)
    internal
    pure
    returns (uint256[] memory _expanded)
  {
    uint256[] memory values = new uint256[](_n);

    for (uint256 i = 0; i < _n; i++) {
      values[i] = uint256(keccak256(abi.encode(_randomness, i)));
    }

    return values;
  }

  /**
   * @dev Gets the TokenData Struct of the tokenId
   * @param _tokenId Id of shihtzu
   */
  function getTokenData(uint256 _tokenId)
    external
    view
    returns (uint256 _lootBoxOptionId, uint256 _seed)
  {
    return (
      tokenIdToData[_tokenId].lootBoxOptionId,
      tokenIdToData[_tokenId].seed
    );
  }

  // function baseTokenURI() public pure override returns (string memory) {
  //   return "https://cryptoshihtzu.herokuapp.com/api/metadata/shihtzu/";
  // }

  // function contractURI() public pure returns (string memory) {
  //   return "https://creatures-api.opensea.io/contract/opensea-creatures";
  // }
}
