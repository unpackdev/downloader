// contracts/CryptoPoopsTraits.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

// OpenZeppelin
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract CryptoPoopTraits is ERC721, Ownable {
  using SafeMath for uint;
  using SafeMath for uint8;
  using SafeMath for uint32;
  using SafeMath for uint64;
  using SafeMath for uint256;

  // Levels of rarity
  uint8 internal constant COMMON = 0;
  uint8 internal constant UNCOMMON = 1;
  uint8 internal constant RARE = 2;
  uint8 internal constant EPIC = 3;
  uint8 internal constant LEGENDARY = 4;
  uint8 internal constant NUM_LEVELS = 5;
  uint8[] internal levelProbabilities;

  // Categories within which we'll randomly assign
  uint8 internal constant BACKGROUNDS = 0;
  uint8 internal constant BACK_ACCESSORIES = 1;
  uint8 internal constant BODIES = 2;
  uint8 internal constant FACES = 3;
  uint8 internal constant FRONT_ACCESSORIES = 4;
  uint8 internal constant NUM_CATEGORIES = 5;

  // List the option numbers that fall into each category in each rarity level
  uint8[][NUM_LEVELS] internal backgroundOptions;
  uint8[][NUM_LEVELS] internal backAccessoryOptions;
  uint8[][NUM_LEVELS] internal bodyOptions;
  uint8[][NUM_LEVELS] internal faceOptions;
  uint8[][NUM_LEVELS] internal frontAccessoryOptions;

  // traitLookup[category][level][i] = an optionId
  uint8[][NUM_LEVELS][NUM_CATEGORIES] internal traitLookup;

  // Mapping from token ID to trait encodings
  mapping (uint256 => uint64) internal _tokenTraits;

  // Fired when an NFT rolls or re-rolls its traits
  event TraitAssigned(address indexed tokenOwner, uint256 tokenId, uint64 encodedTraits);

  constructor() ERC721("CryptoPoops","POOPS") {
    // Initialize number boundaries for each rarity level, on a 100-sided die:
    // 65% chance of common, 20% uncommon, 10% rare, 4% epic, 1% legendary
    levelProbabilities = [65, 85, 95, 99, 100];

    // Initialize lookup data
    traitLookup = [
      backgroundOptions,
      backAccessoryOptions,
      bodyOptions,
      faceOptions,
      frontAccessoryOptions
    ];
  }

  /*
   * Choose a random rarity level
   */
  function randomLevel() internal returns(uint8) {
    uint highestLevel = COMMON;
    uint randomNumber = uint(keccak256(abi.encodePacked(
      block.timestamp, msg.sender, block.number, traitNonce))) % 100;
    while ((highestLevel < NUM_LEVELS) &&
           (randomNumber >= levelProbabilities[highestLevel])) {
      highestLevel++;
    }
    traitNonce++;
    return uint8(highestLevel);
  }

  /*
   * Choose a random trait from the specified category and rarity level
   * @dev traitLookup[_category][_level] contains an array of IDs for this level and category
   */
  function randomTrait(uint8 _level, uint8 _category) internal returns(uint8) {
    uint numOptions =  traitLookup[_category][_level].length;
    require(numOptions >= 1, "Category/level traits not set yet");
    uint randomNumber = uint(keccak256(abi.encodePacked(
      block.timestamp, msg.sender, block.number, traitNonce))) % numOptions;
    uint randomOptionId = traitLookup[_category][_level][randomNumber];
    traitNonce++;
    return uint8(randomOptionId);
  }

  /*
   * Encode traits into a single uint
   *
   * @dev an encoded uint64 that can store up to 8 distinct categories of max 32 options each
   * The structure is the following:
   * | unused byte | unused byte | unused byte | front acc | faces | bodies | back acc | backgrounds |
   */
  function encodeTraits(uint8[NUM_CATEGORIES] memory _traits) internal pure returns(uint64) {
    uint64 encodedTraits= 0;
    for (uint8 i; i < NUM_CATEGORIES; i++) {
      encodedTraits |= (uint64(_traits[i]) << (8 * i));
    }
    return encodedTraits;
  }

  /*
   * Set the rarity level options for the trait encoding
   *
   * @dev This allows for lower gas in contract deploy and avoids potential gaslimit overruns
   * MUST SET THESE AT LEAST ONCE BEFORE STARTING THE SALE
   */
  function setLevelProbabilities(uint8[] calldata _levelProbabilities) external onlyOwner {
    require(_levelProbabilities.length == NUM_LEVELS,
            "Array length doesn't match number of levels");
    levelProbabilities = _levelProbabilities;
  }

  /*
   * Set the trait options for the trait encoding for a given category, by rarity level
   *
   * @dev This allows for lower gas in contract deploy and avoids potential gaslimit overruns
   * MUST SET THESE AT LEAST ONCE BEFORE STARTING THE SALE
   */
  function setCategoryOptions(uint8[] calldata _commonOptions, uint8[] calldata _uncommonOptions,
      uint8[] calldata _rareOptions, uint8[] calldata _epicOptions, uint8[] calldata _legendaryOptions,
      uint8 _categoryNumber) external onlyOwner {
    require(_categoryNumber < NUM_CATEGORIES, "Category doesn't exist");

    traitLookup[_categoryNumber][COMMON] = _commonOptions;
    traitLookup[_categoryNumber][UNCOMMON] = _uncommonOptions;
    traitLookup[_categoryNumber][RARE] = _rareOptions;
    traitLookup[_categoryNumber][EPIC] = _epicOptions;
    traitLookup[_categoryNumber][LEGENDARY] = _legendaryOptions;
  }

  /*
   * Get the trait options for a given category and rarity combination
   *
   * @dev Useful in testing and may be useful for a contract ecosystem
   */
  function getCategoryOptions(uint8 _categoryNumber, uint8 _rarityLevel) external view returns(uint8[] memory) {
    require(_categoryNumber < NUM_CATEGORIES, "Category number doesn't exist");
    require(_rarityLevel < NUM_LEVELS, "Rarity level doesn't exist");

    uint numOptions = traitLookup[_categoryNumber][_rarityLevel].length;
    uint8[] memory options = new uint8[](numOptions);

    for (uint i; i < numOptions; i++) {
      options[i] = traitLookup[_categoryNumber][_rarityLevel][i];
    }

    return options;
  }

}
