// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,_@       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at farmhand@thefarm.game
 * Found a broken egg in our contracts? We have a bug bounty program bugs@thefarm.game
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;
import "./OwnableUpgradeable.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./ERC721ACheckpointableUpgradeable.sol";
import "./IEggShop.sol";
import "./IEGGToken.sol";
import "./IFarmAnimals.sol";
import "./IFarmAnimalsTraits.sol";
import "./IHenHouse.sol";
import "./IRandomizer.sol";
import "./DefaultOperatorFilterer.sol";

contract FarmAnimals is
  ERC721AQueryableUpgradeable,
  IFarmAnimals,
  OwnableUpgradeable,
  ERC2981ContractWideRoyalties,
  ERC721ACheckpointableUpgradeable,
  DefaultOperatorFilterer
{
  // General Events
  event InitializedContract(address thisContract);
  event Mint(string kind, address indexed owner, uint256 indexed tokenId);
  event Burn(string kind, uint256 indexed tokenId);
  event HenTwinMinted(address indexed receipt1, uint256 tokenId1, address indexed receipt2, uint256 tokenId2);
  event AdvantageUpdated(
    address indexed owner,
    uint256 indexed tokenId,
    string indexed kind,
    uint256 previousAdvantage,
    uint256 newAdvantage
  );

  uint256 public maxSupply; // max number of tokens that can be minted

  uint256 public maxGen0Supply; // number of tokens that can be claimed for a fee

  uint256 public minted; // number of tokens have been minted so far

  uint256 public mintedRoosters; // number of roosters that have been minted so far

  uint256 private maxRoosters; // max number of allowed roosters to be minted

  uint256 private twinsMinted; // used to expand the maxGen0Supply by 5

  uint16[6] private coyoteChance; // array for the coyote chance per step

  uint16[6] private roosterChance; // array for the rooster chance per step

  uint16[6] private roosterSupply; // array for the rooster supply per step

  mapping(uint256 => Traits) private tokenTraits; // mapping from tokenId to a struct containing the token's traits

  mapping(uint256 => bool) private knownCombinations; // Store previous trait combinations to prevent duplicates

  // list of probabilities for each trait type
  uint8[][25] private rarities;

  // list of aliases for Walker's Alias algorithm
  uint8[][25] private aliases;

  IEGGToken private eggToken; // ref to EGG token
  IEggShop private eggShop; // ref to eggShop collection
  IFarmAnimalsTraits private farmAnimalsTraits; // ref to Traits
  IHenHouse private henHouse; // ref to the HenHouse contract
  IRandomizer public randomizer; // ref randomizer contract

  // address => allowedToCallFunctions
  mapping(address => bool) private controllers;

  uint16 private applePieTypeId; // Egg shop type IDs

  /** MODIFIERS */

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  function initialize(
    uint256 _maxGen0Supply,
    IEggShop _eggShop,
    IEGGToken _eggToken,
    IFarmAnimalsTraits _farmAnimalsTraits,
    IRandomizer _randomizer,
    uint16[] memory _coyoteChance,
    uint16[] memory _roosterChance,
    uint16[] memory _roosterSupply
  ) public initializerERC721A initializer {
    __ERC721A_init('TFG: Farm Animals', 'TFGFA');
    __Ownable_init();

    controllers[_msgSender()] = true;

    maxSupply = _maxGen0Supply * 6;
    maxGen0Supply = _maxGen0Supply;

    eggShop = _eggShop;
    eggToken = _eggToken;
    farmAnimalsTraits = _farmAnimalsTraits;
    randomizer = _randomizer;

    _setCoyoteChance(_coyoteChance);
    _setRoosterChance(_roosterChance);
    _setRoosterSupply(_roosterSupply);

    maxRoosters = 990;

    twinsMinted = 1;

    applePieTypeId = 1;
    emit InitializedContract(address(this));
  }

  /**
   *  ███    ███ ██ ███    ██ ████████
   *  ████  ████ ██ ████   ██    ██
   *  ██ ████ ██ ██ ██ ██  ██    ██
   *  ██  ██  ██ ██ ██  ██ ██    ██
   *  ██      ██ ██ ██   ████    ██
   */

  /**
   * @notice Mint a quantity of tokens
   * @dev This will just generate random traits and mint tokens to a designated address
   * @param recipient The address to recieve the minted NFT
   * @param seeds array of predetermined seeds
   */
  function mintSeeds(address recipient, uint256[] calldata seeds) external onlyController {
    uint256 quantity = seeds.length;

    for (uint256 i = 1; i <= seeds.length; ) {
      uint256 seed = seeds[i - 1];

      if (seed == 0) {
        quantity--;
      } else {
        minted++;

        Kind kind = _generateAndStoreTraits(minted, seed, 3, 0, false).kind;
        emit Mint(kind == Kind.HEN ? 'HEN' : kind == Kind.COYOTE ? 'COYOTE' : 'ROOSTER', recipient, minted);
      }

      unchecked {
        i++;
      }
    }

    // Assign the token IDs to the minter
    _mint(recipient, quantity);
  }

  /**
   * @notice Mint a specific token - All payment / game logic / quantity should be handled in the game contract.
   * @dev This will just generate random traits and mint a token to a designated address.
   * @param seed The seed used to mint the NFT
   * @param recipient1 The address to recieve the first twin NFT
   * @param recipient2 The address to recieve the second twin NFT (may be different if stolen)
   */
  function mintTwins(
    uint256 seed,
    address recipient1,
    address recipient2
  ) external onlyController {
    minted++;
    _generateAndStoreTraits(minted, seed, 0, 0, false);
    minted++;
    _generateAndStoreTraits(minted, seed, 0, 0, true);

    if (recipient1 == recipient2) {
      _mint(recipient1, 2);
    } else {
      _mint(recipient1, 1);
      _mint(recipient2, 1);
    }

    emit Mint('HEN', recipient1, minted - 1);
    emit Mint('HEN', recipient2, minted);
    emit HenTwinMinted(recipient1, minted - 1, recipient2, minted);

    // Need to round up the gen0 supply to the nearest 5 so everyone can mint

    if (minted <= maxGen0Supply) {
      if (twinsMinted == 1) {
        _setMaxGen0Supply(_ceil(maxGen0Supply + 1, 5));
      }
      twinsMinted++;

      if (twinsMinted == 6) {
        twinsMinted = 1;
      }
    }
  }

  /**
   * @notice Mint a specific token - All payment / game logic / quantity should be handled in the game contract.
   * @dev This will just generate random traits and mint a token to a designated address.
   * @param recipient The address to recieve the minted NFT
   * @param seed The seed used to mint the NFT
   * @param twinHen state for the twins or single hen mint
   * @param specificKind the value of the specific kind of nft (0 => hen, 1 => coyote, 2 => rooster, 3 => random)
   */
  function specialMint(
    address recipient,
    uint256 seed,
    uint16 specificKind,
    bool twinHen,
    uint16 quantity
  ) external override onlyController {
    require(minted + quantity <= maxSupply, 'All minted');
    for (uint16 i = 0; i < quantity; i++) {
      minted++;

      Kind kind = _generateAndStoreTraits(minted, seed, specificKind, 0, false).kind;

      _mint(recipient, 1);
      emit Mint(kind == Kind.HEN ? 'HEN' : kind == Kind.COYOTE ? 'COYOTE' : 'ROOSTER', recipient, minted);
      if (twinHen && specificKind == 0) {
        minted++;
        _generateAndStoreTraits(minted, seed, specificKind, 0, true);
        _mint(recipient, 1);
        emit Mint('HEN', recipient, minted);
        emit HenTwinMinted(recipient, minted - 1, recipient, minted);
      }
    }
  }

  /**
   * @notice Burn a token - any game logic / quantity should be handled before this function.
   * @param tokenId The token ID of the NFT to burn
   */
  function burn(uint256 tokenId) external onlyController {
    require(ownerOf(tokenId) == tx.origin, 'Not owner');
    Kind kind = tokenTraits[tokenId].kind;
    super._burn(tokenId);
    emit Burn(kind == Kind.HEN ? 'HEN' : kind == Kind.COYOTE ? 'COYOTE' : 'ROOSTER', tokenId);
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  function _ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 ceilNumber = ((a + m - 1) / m) * m;
    return ceilNumber;
  }

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice Adapted from `_transferTokens()` in `Comp.sol` to update delegate votes.
   * @dev hooks into OpenZeppelin's `ERC721._transfer`
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 tokenId,
    uint256 quantity
  ) internal virtual override(ERC721AUpgradeable, ERC721ACheckpointableUpgradeable) {
    super._beforeTokenTransfers(from, to, tokenId, quantity);

    // Checks to make sure its Gen0 before issuing votes
    if (tokenId <= maxGen0Supply) {
      /// @notice Differs from `_transferTokens()` to use `delegates` override method to simulate auto-delegation
      _moveDelegates(
        delegates(from),
        delegates(to),
        safe96(quantity, 'ERC721Checkpointable::votesToDelegate: amount exceeds 96 bits')
      );
    }
  }

  /**
   * @notice Generate and store character traits. Recursively called to ensure uniqueness.
   * @dev Give users 6 attempts, bit shifting the seed each time (uses 5 bytes of entropy before failing)
   * @param _tokenId id of the token to generate traits
   * @param seed random 256 bit seed to derive traits
   * @param twinHen state for the twins or single hen mint
   * @param specificKind the value of the specific kind of nft (0 => hen, 1 => coyote, 2 => rooster, 3 => random)
   * @return tTraits character trait struct
   */
  function _generateAndStoreTraits(
    uint256 _tokenId,
    uint256 seed,
    uint16 specificKind,
    uint8 attempt,
    bool twinHen
  ) internal returns (Traits memory tTraits) {
    require(attempt < 5, 'Could not gen unique traits');
    tTraits = _selectTraits(seed, specificKind);

    if (tTraits.kind == Kind.ROOSTER) {
      mintedRoosters++;
    }
    if (!twinHen) {
      if (!knownCombinations[_structToHash(tTraits)]) {
        tokenTraits[_tokenId] = tTraits;
        knownCombinations[_structToHash(tTraits)] = true;
        return tTraits;
      }
      return _generateAndStoreTraits(_tokenId, seed >> attempt, specificKind, attempt + 1, twinHen);
    } else {
      tokenTraits[_tokenId] = tTraits;
      return tTraits;
    }
  }

  function _getCurrentChance()
    internal
    view
    returns (
      uint16,
      uint16,
      uint16
    )
  {
    uint16 currentStep = _getCurrentStep();
    uint16 roosterMaxTokens = 0;
    for (uint16 i = 0; i <= currentStep; i++) {
      roosterMaxTokens += roosterSupply[i];
    }
    return (coyoteChance[currentStep], roosterChance[currentStep], roosterMaxTokens);
  }

  /**
   * @notice get the number of current step 0 => Gen0 1 => Gen1 ... 5 => Gen5
   */

  function _getCurrentStep() internal view returns (uint16 currentStep) {
    uint256 gAmount = (maxSupply - maxGen0Supply) / 5;
    if (minted <= maxGen0Supply) return 0; // GEN 0
    if (minted <= (gAmount + maxGen0Supply)) return 1; // GEN 1
    if (minted <= (gAmount * 2) + maxGen0Supply) return 2; // GEN 2
    if (minted <= (gAmount * 3) + maxGen0Supply) return 3; // GEN 3
    if (minted <= (gAmount * 4) + maxGen0Supply) return 4; // GEN 4
    return 5; // GEN 5
  }

  /**
   * @notice Uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
   * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
   * probability & alias tables are generated off-chain beforehand
   * @param seed portion of the 256 bit seed to remove trait correlation
   * @param traitType the trait type to select a trait for
   * @return the ID of the randomly selected trait
   */
  function _selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
    uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
    // If a selected random trait probability is selected (biased coin) return that trait
    if (seed >> 8 < rarities[traitType][trait]) return trait;
    return aliases[traitType][trait];
  }

  function pickKind(uint256 seed, uint16 specificKind) public view onlyController returns (Kind k) {
    return _pickKind(seed, specificKind);
  }

  function _pickKind(uint256 seed, uint16 specificKind) internal view returns (Kind k) {
    // HEN=0, COYOTE=1, ROOSTER=2 // RANDOM=3
    if (specificKind == 3) {
      (uint16 rChance, uint16 cChance, uint16 rMaxTokens) = _getCurrentChance();
      if (mintedRoosters <= rMaxTokens && mintedRoosters <= maxRoosters) {
        uint256 mod = (seed & 0xFFFFF) % 100;
        k = Kind(mod < rChance ? 1 : mod < rChance + cChance ? 2 : 0);
      } else {
        k = Kind((seed & 0xFFFFF) % cChance == 0 ? 1 : 0);
      }
    } else {
      k = Kind(specificKind);
    }
    return k;
  }

  /**
   * @notice Selects the character and all of its traits based on the seed value
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @param specificKind the value of the specific kind of nft (0 => hen, 1 => coyote, 2 => rooster, 3 => random)
   * @return t struct of randomly selected traits
   */
  function _selectTraits(uint256 seed, uint16 specificKind) internal view returns (Traits memory t) {
    t.kind = pickKind(seed, specificKind);
    // Use 112 bytes of seed entropy to define traits.
    uint8 offset = uint8(t.kind) * 8; // 																HEN					COYOTE				ROOSTER
    seed >>= 16;
    t.traits[0] = _selectTrait(uint16(seed & 0xFFFFF), 0 + offset); // 00 Body      08 Body   	  16 Body
    seed >>= 16;
    t.traits[1] = _selectTrait(uint16(seed & 0xFFFFF), 1 + offset); // 01 Clothes   09 Clothes    17 Clothes
    seed >>= 16;
    t.traits[2] = _selectTrait(uint16(seed & 0xFFFFF), 2 + offset); // 02 Beak      10 Ears(fake) 18 Beak
    seed >>= 16;
    t.traits[3] = _selectTrait(uint16(seed & 0xFFFFF), 3 + offset); // 03 Eyes      11 Eyes   		19 Eyes
    seed >>= 16;
    t.traits[4] = _selectTrait(uint16(seed & 0xFFFFF), 4 + offset); // 04 Feet      12 Feet    	  20 Feet
    seed >>= 16;
    t.traits[5] = _selectTrait(uint16(seed & 0xFFFFF), 5 + offset); // 05 Head      13 Head    	  21 Head
    seed >>= 16;
    t.traits[6] = _selectTrait(uint16(seed & 0xFFFFF), 6 + offset); // 06 Mouth     14 Mouth 		  22 Mouth
    t.advantage = _selectTrait(uint16(seed & 0xFFFFF), 7 + offset); // 07 Prod 		  15 Wily				23 Guard
  }

  /**
   * @notice Converts a struct to a 256 bit hash to check for uniqueness
   * @param t the struct to pack into a hash
   * @return the 256 bit hash of the struct
   */
  function _structToHash(Traits memory t) internal pure returns (uint256) {
    return
      uint256(
        bytes32(
          abi.encodePacked(
            t.traits[0],
            t.traits[1],
            t.traits[2],
            t.traits[3],
            t.traits[4],
            t.traits[5],
            t.traits[6],
            t.kind,
            t.advantage
          )
        )
      );
  }

  /**
   * @notice Set the mint chance of the rooster per step
   * @param _chances the array for the mint chance of the rooster per step
   */

  function _setRoosterChance(uint16[] memory _chances) internal {
    for (uint16 i = 0; i < _chances.length; i++) {
      roosterChance[i] = _chances[i];
    }
  }

  /**
   * @notice Set the mint chance of the coyote per step
   * @param _chances the array for the mint chance of the coyote per step
   */

  function _setCoyoteChance(uint16[] memory _chances) internal {
    for (uint16 i = 0; i < _chances.length; i++) {
      coyoteChance[i] = _chances[i];
    }
  }

  /**
   * @notice Set the rooster max supply per step
   * @param _supply the array for the rooster max supply per step
   */

  function _setRoosterSupply(uint16[] memory _supply) internal {
    for (uint16 i = 0; i < _supply.length; i++) {
      roosterSupply[i] = _supply[i];
    }
  }

  /**
   * @notice Override _startTokenId function of ERC721A starndard contract
   */

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    returns (bool)
  {
    if (controllers[owner] || controllers[operator]) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  /** Traits */

  /**
   * @notice Expose traits to trait contract.
   * @dev Only callable by the owner.
   * @param tokenId Token ID of toke to get traits for
   */
  function getTokenTraits(uint256 tokenId) external view onlyController returns (Traits memory) {
    require(_exists(tokenId), "Token doesn't exist");
    return tokenTraits[tokenId];
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    returns (string memory)
  {
    require(_exists(tokenId), "Token doesn't exist");
    return farmAnimalsTraits.tokenURI(tokenId);
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Set the _collectionName
   * @dev Only callable by the owner
   * @param _newName the NFT collection name
   * @param _newDesc the NFT collection description
   * @param _newImageUri the NFT collection impage URL (ipfs://folder/to/cid)
   * @param _newFee set the NFT royalty fee 10% max percentage (using 2 decimals - 10000 = 100, 0 = 0)
   * @param _newRecipient set the address of the royalty fee recipient
   */
  function setCollectionInfo(
    string memory _newName,
    string memory _newDesc,
    string memory _newImageUri,
    string memory _newExtLink,
    uint16 _newFee,
    address _newRecipient
  ) external onlyOwner {
    _collectionName = _newName;
    _collectionDescription = _newDesc;
    _imageUri = _newImageUri;
    _externalLink = _newExtLink;
    _sellerRoyaltyFee = _newFee;
    _recipient = _newRecipient;
    _setRoyalties(_newRecipient, _newFee);
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by an existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by an existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice Set multiple contract addresses
   * @dev Only callable by an existing controller
   * @param _eggShop Address of eggShop contract
   * @param _eggToken Address of eggToken contract
   * @param _farmAnimalTraits Address of farmAnimalTraits contract
   * @param _henHouse Address of henHouse contract
   * @param _randomizer Address of randomizer contract
   */

  function setExtContracts(
    address _eggShop,
    address _eggToken,
    address _farmAnimalTraits,
    address _henHouse,
    address _randomizer
  ) external onlyController {
    eggShop = IEggShop(_eggShop);
    eggToken = IEGGToken(_eggToken);
    farmAnimalsTraits = IFarmAnimalsTraits(_farmAnimalTraits);
    henHouse = IHenHouse(_henHouse);
    randomizer = IRandomizer(_randomizer);
  }

  /**
   * @notice Set the henHouse contract address
   * @dev Only callable by the owner
   * @param _address Address of Hen House contract
   */
  function setHenHouse(address _address) external onlyController {
    henHouse = IHenHouse(_address);
  }

  function _setMaxGen0Supply(uint256 _supply) internal {
    require(_supply % 5 == 0, 'Must be div by 5');
    maxGen0Supply = _supply;
    maxSupply = _supply * 6;
  }

  /**
   * @notice Updates the number of tokens for Gen0 ETH sales
   * @dev Gen0 is used to set maxSupply (Gen0 * 6)
   * @param _supply Number of Gen0 tokens
   */
  function setMaxGen0Supply(uint256 _supply) public onlyOwner {
    _setMaxGen0Supply(_supply);
  }

  /**
   * @notice Updates the number of tokens for Gen1+ EGG sales
   * @dev Gen0 is sub from maxSupply, then div by 5 to get each step
   * @param _supply Number of Gen0 + Gen1+ tokens
   *
   */
  function setMaxSupply(uint256 _supply) external onlyOwner {
    maxSupply = _supply;
  }

  /**
   * @notice Update the NFT Trait's advantage by Id
   * @dev Only callable by the controller
   * @param tokenId NFT Token Id to update trait advantage
   * @param score amount to apply to increment / decrement
   * @param decrement Boolean, if true then decrement, else increment advantage by score
   */

  function updateAdvantage(
    uint256 tokenId,
    uint8 score,
    bool decrement
  ) external onlyController {
    uint8 _advantage = tokenTraits[tokenId].advantage;
    Kind kind = tokenTraits[tokenId].kind;

    if (decrement) {
      tokenTraits[tokenId].advantage = _advantage - score;
    } else {
      tokenTraits[tokenId].advantage = _advantage + score;
      uint8 _upgradeAdvantage = tokenTraits[tokenId].advantage;
      emit AdvantageUpdated(
        _msgSender(),
        tokenId,
        kind == Kind.HEN ? 'HEN' : kind == Kind.COYOTE ? 'COYOTE' : 'ROOSTER',
        _advantage + 5,
        _upgradeAdvantage + 5
      );
    }
  }

  /**
   * @notice Update the rarties & aliase for traitTypeIds
   * @dev Only callable by the controller
   * @param _traitTypeIds array of traitTypeIds
   * @param _rarities array of rarities for traitType
   * @param _aliases array of aliases for traitType
   */

  function updateRaritiesAliases(
    uint8[] calldata _traitTypeIds,
    uint8[][] calldata _rarities,
    uint8[][] calldata _aliases
  ) external onlyController {
    require(_rarities.length == _aliases.length, 'Rarities should = Aliases lenght');
    uint256 max = _traitTypeIds.length;
    for (uint256 i = 0; i < max; ) {
      rarities[_traitTypeIds[i]] = _rarities[i];
      aliases[_traitTypeIds[i]] = _aliases[i];
      unchecked {
        i++;
      }
    }
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Base)
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata
      interfaceId == 0x2a55205a; // ERC165 interface ID for ERC2981
  }
}
