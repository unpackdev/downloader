// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./CryptoShihTzu.sol";

/**
 * @title LootBox
 * LootBox - a NFT contract that holds the minted Loot Boxes for the CRYPTO Shih Tzus.
 */
contract LootBox is ERC721Tradable {
  address public shihtzuAddress;

  struct Option {
    uint16[4] probabilities;
    uint256 totalSupply;
  }

  mapping(uint256 => Option) public options;
  uint256 public optionCount = 0;

  mapping(address => bool) public minters;

  mapping(uint256 => uint256) public tokenIdToOptionId;

  constructor(address _proxyRegistryAddress, string memory _baseTokenURI)
    ERC721Tradable(
      "CryptoShihTzuBox",
      "CSB",
      _proxyRegistryAddress,
      _baseTokenURI
    )
  {
    // basic pack
    addOption([6000, 8500, 9800, 10000], 8000);

    // premium pack
    addOption([3000, 6500, 9300, 10000], 2000);

    // diamond pack
    addOption([0, 4000, 8500, 10000], 300);

    // supporter box
    addOption([3000, 6000, 9000, 10000], 10);
  }

  /**
   * @dev Add a address that can mint tokens
   * @param _minter address of the minter
   */
  function addMinter(address _minter) external onlyOwner {
    minters[_minter] = true;
  }

  /**
   * @dev Remove an address that can mint tokens
   * @param _minter address of the minter
   */
  function removeMinter(address _minter) external onlyOwner {
    delete minters[_minter];
  }

  /**
   * @dev Only addresses from minter mapping or owner can mit
   */
  modifier onlyMinter() {
    require(
      owner() == _msgSender() || minters[_msgSender()],
      "onlyMinter: Not a minter or owner"
    );
    _;
  }

  /**
   * @dev Set the shih tzu address to mint the lootbox content to
   * @param _shihtzuAddress address of the shih tzu nft contract
   */
  function setShihTzuAddress(address _shihtzuAddress) external onlyOwner {
    shihtzuAddress = _shihtzuAddress;
  }

  /**
   * @dev Adds a lootbox, should only be called from the constructor to prevent increasing supply
   * @param _probabilites The drop rate of the various rarities
   * @param _totalSupply The total supply available for this lootbox
   */
  function addOption(uint16[4] memory _probabilites, uint256 _totalSupply)
    private
  {
    optionCount++;
    options[optionCount] = Option(_probabilites, _totalSupply);
  }

  /**
   * @dev Mint token and requests randomness for attribute generation
   * @param _to address of the future owner of the token
   * @param _optionId The id of the lootbox option
   */
  function mintTo(address _to, uint256 _optionId) public onlyMinter {
    require(options[_optionId].totalSupply > 0, "No supply");

    uint256 _newTokenId = _getNextTokenId();
    _mint(_to, _newTokenId);
    _incrementTokenId();

    tokenIdToOptionId[_newTokenId] = _optionId;
    options[_optionId].totalSupply--;
  }

  /**
   * @dev Mint token and requests randomness for attribute generation
   * @param _tokenId The id of token to open
   */
  function open(uint256 _tokenId) external {
    require(ownerOf(_tokenId) == _msgSender(), "Not the owner of this lootbox");

    // destroy lootbox after opening it
    _burn(_tokenId);

    CryptoShihTzu _shihtzu = CryptoShihTzu(shihtzuAddress);
    _shihtzu.mintTo(_msgSender(), tokenIdToOptionId[_tokenId]);

    // delete tokenIdToOptionId[_tokenId];
  }

  /**
   * @dev Gets the lootbox with id
   * @param _lootBoxOptionId Id of lootbox
   */
  function getOption(uint256 _lootBoxOptionId)
    external
    view
    returns (uint256 _totalSupply, uint16[4] memory _probabilities)
  {
    return (
      options[_lootBoxOptionId].totalSupply,
      options[_lootBoxOptionId].probabilities
    );
  }

  // function baseTokenURI() public pure override returns (string memory) {
  //   return "https://cryptoshihtzu.herokuapp.com/api/metadata/lootbox/";
  // }

  // function contractURI() public pure returns (string memory) {
  //   return "https://creatures-api.opensea.io/contract/opensea-creatures";
  // }
}
