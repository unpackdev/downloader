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

import "./MerkleProofUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./IEggCitement.sol";
import "./IEGGToken.sol";
import "./IEggShop.sol";
import "./IFarmAnimals.sol";
import "./IHenHouse.sol";
import "./IRandomizer.sol";

contract TheFarmGameMint is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  event MintCommitted(address indexed owner, uint256 indexed quantity);
  event MintRevealed(address indexed owner, uint256 indexed quantity);
  event EggShopAward(address indexed recipient, uint256 indexed typeId);
  event SaleStatusUpdated(
    uint256 preSaleTime,
    uint256 allowListTime,
    uint256 preSaleFee,
    uint256 preSaleStakeFee,
    uint256 publicSaleTime,
    uint256 publicSaleFee,
    uint256 publicStakeFee
  );
  // Kidnappings & rescues
  event TokenKidnapped(address indexed minter, address indexed thief, uint256 indexed tokenId, string kind);
  event ApplePieTaken(address indexed minter, address indexed thief, uint256 indexed tokenId);
  event TokenRescued(address indexed thief, address indexed rescuer, uint256 indexed tokenId, string kind);
  event InitializedContract(address thisContract);

  // PreSale
  uint256 public preSaleTime;

  uint256 public preSaleFee;
  uint256 public preSaleStakeFee;
  uint256 public preSaleMaxQty;
  bytes32 public preSaleRoot; // Merkel root for preSale

  // Allow List
  uint256 public allowListTime;
  bytes32 public allowListRoot; // Merkel root for allow list sale

  mapping(address => uint256) private preSaleMintRecords; // Address => tokenIDs, track number of mints during presale

  // Public Sale Gen 0
  uint256 public publicTime;
  uint256 public publicFee;
  uint256 public publicStakeFee;
  uint256 public publicMaxPerTx;
  uint256 public publicMaxQty;

  mapping(address => uint256) private publicMintRecords; // Address => tokenIDs, track number of mints during Gen0

  uint256 private twinHenRate; // rate for twin hen mint

  uint256 private teamMintInterval; // Auto mints Gen0 token to team every

  // Gen 1+
  uint256 private maxEggCost; // max EGG cost

  // Mint Commit/Reveal
  struct MintCommit {
    bool stake;
    uint16 quantity;
  }
  mapping(address => mapping(uint16 => MintCommit)) private _mintCommits; // address -> commit # -> commits
  mapping(address => uint16) private _pendingCommitId; // address -> commit num of commit need revealed for account
  mapping(uint16 => uint256) private _commitRandoms; // commit # -> offchain random
  uint16 private _commitId;
  uint16 private _lastUsedCommitId;
  uint16 private _pendingMintQty;
  bool public allowCommits;

  // Auto-liquidity
  uint256 private liqudityAlreadyPaid; // Count of tokens that liquidity is already paid for

  // Admin
  mapping(address => bool) private controllers; // address => can call allowedToCallFunctions

  // Egg shop type IDs
  uint256 public applePieTypeId;
  uint256 public platinumEggTypeId;

  // Interfaces
  IEggCitement private eggCitement; // ref to EggCitement contract
  IEggShop public eggShop; // ref to eggShop collection
  IEGGToken public eggToken; // ref to EGG for burning on mint
  IFarmAnimals public farmAnimalsNFT; // ref to NFT collection
  IHenHouse public henHouse; // ref to the Hen House
  IRandomizer public randomizer; // ref randomizer contract

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

  /**
   * Instantiates contract
   * Emits InitilizeContract event to kickstart subgraph
   */

  function initialize(
    address _eggCitement,
    address _eggToken,
    address _eggShop,
    address _farmAnimalsNFT,
    address _henHouse,
    address _randomizer
  ) public initializer {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    eggCitement = IEggCitement(_eggCitement);
    eggToken = IEGGToken(_eggToken);
    eggShop = IEggShop(_eggShop);
    farmAnimalsNFT = IFarmAnimals(_farmAnimalsNFT);
    henHouse = IHenHouse(_henHouse);
    randomizer = IRandomizer(_randomizer);
    controllers[_msgSender()] = true;
    controllers[address(_randomizer)] = true;

    preSaleTime = 1667923200; // Tuesday, November 8, 2022 16:00:00 GMT

    preSaleFee = 0.049 ether;
    preSaleStakeFee = 0.025 ether;
    preSaleMaxQty = 4;

    // Allow List
    allowListTime = 1667928600; // Tuesday, November 8, 2022 17:30:00 GMT

    // Public Sale Gen 0
    publicTime = 1667935800; // Tuesday, November 8, 2022 19:30:00 GMT
    publicFee = 0.049 ether;
    publicStakeFee = 0.035 ether;
    publicMaxPerTx = 5;
    publicMaxQty = 25;

    twinHenRate = 2; // rate for twin hen mint

    teamMintInterval = 25; // Auto mints Gen0 token to team every

    maxEggCost = 72000 ether; // max EGG cost

    _commitId = 1;
    _lastUsedCommitId = 1;
    _pendingMintQty;
    allowCommits = false;

    // Auto-liquidity
    liqudityAlreadyPaid = 0; // Count of tokens that liquidity is already paid for

    // Egg shop type IDs
    applePieTypeId = 1;
    platinumEggTypeId = 5;

    _pause();
    emit InitializedContract(address(this));
  }

  /**
   *  ███    ███ ██ ███    ██ ████████
   *  ████  ████ ██ ████   ██    ██
   *  ██ ████ ██ ██ ██ ██  ██    ██
   *  ██  ██  ██ ██ ██  ██ ██    ██
   *  ██      ██ ██ ██   ████    ██
   * This section has everything to do with Character minting and burning
   */

  /**
   * Mint Commit
   */

  /**
   * @notice Mint via preSale merkle tree for ETH
   * @dev Only callable if public sale has not started && contracts have been set
   * @param quantity number of NFTs to mint in this transaction
   * @param stake stake NFTs upon minting
   * @param merkleProof merkle proof for msg.sender
   */
  function preSaleMint(
    uint16 quantity,
    bool stake,
    bytes32[] memory merkleProof
  ) external payable whenNotPaused nonReentrant {
    require(allowCommits, 'Adding commits disallowed');
    require(_pendingCommitId[_msgSender()] == 0, 'Already have pending mints');
    require(tx.origin == _msgSender() || controllers[_msgSender()], 'Only EOA or controllers');
    require(block.timestamp >= preSaleTime && block.timestamp < publicTime, 'Pre-sale not running');
    uint256 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    require(minted + _pendingMintQty + quantity <= gen0Supply, 'Qty greater than available tokens');

    bytes32 node = keccak256(abi.encode(msg.sender));
    if (block.timestamp >= preSaleTime && block.timestamp < allowListTime) {
      require(
        MerkleProofUpgradeable.verify(merkleProof, preSaleRoot, node),
        'Minters address not eligible for preSale mint'
      );
    } else if (block.timestamp >= allowListTime) {
      require(
        MerkleProofUpgradeable.verify(merkleProof, allowListRoot, node),
        'Minters address not eligible for allow list mint'
      );
    }

    require(
      preSaleMintRecords[_msgSender()] + quantity <= preSaleMaxQty,
      'Mint would exceed minters address max allowed'
    );

    preSaleMintRecords[_msgSender()] = preSaleMintRecords[_msgSender()] + quantity;

    // Price Calc
    uint256 totalEthCost = 1;
    if (stake) {
      totalEthCost = preSaleStakeFee * quantity;
    } else {
      totalEthCost = preSaleFee * quantity;
    }
    require(msg.value >= totalEthCost, 'Payment amount is not correct.');

    _mintCommit(quantity, stake);
  }

  /**
   * @notice Mint public sale Gen 0 for ETH
   * @dev Initiate the start of a mint. This action collects ETH, as the intent of committing is that you cannot back out once you've started.
   * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
   * commit was added to.
   * @param quantity number of NFTs to mint in this transaction
   * @param stake stake NFTs upon minting
   */

  function mintCommitGen0(uint16 quantity, bool stake) external payable whenNotPaused nonReentrant {
    require(allowCommits, 'Adding commits disallowed');
    require(tx.origin == _msgSender() || controllers[_msgSender()], 'Only EOA or controllers');
    require(_pendingCommitId[_msgSender()] == 0, 'Already have pending mints');
    require(block.timestamp >= publicTime, 'Public sale not yet started');
    uint256 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();

    require(quantity > 0 && quantity <= publicMaxPerTx, 'Invalid mint qty');
    require(minted + _pendingMintQty + quantity <= gen0Supply, 'Qty greater than available tokens');

    require(
      publicMintRecords[_msgSender()] + quantity <= publicMaxQty,
      'Mint would exceed minters address max allowed'
    );

    publicMintRecords[_msgSender()] = publicMintRecords[_msgSender()] + quantity;

    uint256 totalEthCost = 1;

    for (uint256 i = 1; i < quantity; ) {
      // Gen0 Price
      if (stake) {
        totalEthCost = publicStakeFee * quantity;
      } else {
        totalEthCost = publicFee * quantity;
      }
      unchecked {
        i++;
      }
    }

    require(msg.value >= totalEthCost, 'Invalid ETH amount');
    _mintCommit(quantity, stake);
  }

  /**
   * @dev Initiate the start of a mint. This action burns EGG, as the intent of committing is that you cannot back out once you've started.
   * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
   * commit was added to. */
  function mintCommitGen1(uint16 quantity, bool stake) external whenNotPaused nonReentrant {
    require(allowCommits, 'Adding commits disallowed');
    require(tx.origin == _msgSender(), 'Only EOA');
    require(_pendingCommitId[_msgSender()] == 0, 'Already have pending mints');
    uint256 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 maxSupply = farmAnimalsNFT.maxSupply();
    require(minted >= gen0Supply, 'Gen 0 not fully minted');
    require(minted + _pendingMintQty + quantity <= maxSupply, 'All tokens minted');
    require(quantity > 0 && quantity <= 10, 'Invalid mint qty');

    uint256 totalEggCost = 0;
    // Loop through the quantity to get total price
    for (uint256 i = 1; i <= quantity; ) {
      totalEggCost += mintCostEGG(minted + _pendingMintQty + i);
      unchecked {
        i++;
      }
    }

    if (totalEggCost > 0) {
      eggToken.burn(_msgSender(), totalEggCost);
    }

    _mintCommit(quantity, stake);
  }

  function _mintCommit(uint16 _quantity, bool _stake) internal {
    _lastUsedCommitId = _commitId;
    _mintCommits[_msgSender()][_commitId] = MintCommit(_stake, _quantity);
    _pendingCommitId[_msgSender()] = _commitId;
    _pendingMintQty += _quantity;
    emit MintCommitted(_msgSender(), _quantity);
  }

  /**
   * Mint Reveal
   */

  // Using Struct to avoice stack too deep
  struct RevealInfo {
    uint256 startingTokenId;
    uint256 numOfTotalMints;
    uint256 numToMints;
  }

  /**
   * @dev Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
   * 			the user is pending for has been assigned a random seed.
   */
  function mintReveal() external nonReentrant {
    require(tx.origin == _msgSender(), 'Only EOA');
    uint256 minted = farmAnimalsNFT.minted();
    uint256 maxGen0Supply = farmAnimalsNFT.maxGen0Supply();
    if (minted < maxGen0Supply) {
      revealGen0(tx.origin);
    } else {
      revealGen1(tx.origin);
    }
  }

  function revealGen0(address _address) internal {
    uint16 commitIdCur = _pendingCommitId[_address];

    require(commitIdCur > 0, 'No pending commit');
    require(_commitRandoms[commitIdCur] > 0, 'Random seed not set');
    uint256 minted = farmAnimalsNFT.minted();

    MintCommit memory commit = _mintCommits[_address][commitIdCur];
    _pendingMintQty -= commit.quantity;

    uint256 startingTokenId = minted + 1;

    uint256[] memory seeds = new uint256[](commit.quantity);

    uint256 seed = _commitRandoms[commitIdCur];
    address recipient = _address;

    if (commit.stake) {
      recipient = address(henHouse);
    }

    uint256 numOfTotalMints = commit.quantity;
    uint256 numToMints = commit.quantity;

    for (uint256 i = 1; i <= commit.quantity; ) {
      seed = uint256(keccak256(abi.encode(seed, _address, commitIdCur, i)));
      IFarmAnimals.Kind kind = farmAnimalsNFT.pickKind(seed, 3);
      if (kind == IFarmAnimals.Kind.HEN && seed % 100 < twinHenRate) {
        farmAnimalsNFT.mintTwins(seed, recipient, recipient);
        numOfTotalMints++;
        numToMints--;
      } else {
        seeds[i - 1] = seed;
      }

      unchecked {
        i++;
      }
    }

    if (numToMints > 0) {
      farmAnimalsNFT.mintSeeds(recipient, seeds);
    }

    bool mintToTeam = false;

    uint16[] memory tokenIds = new uint16[](numOfTotalMints);
    for (uint256 i; i < numOfTotalMints; i++) {
      uint256 currentId = startingTokenId + i;
      // Give bonus to first 1111 minters
      if (currentId <= 1111) {
        eggCitement.giveReward(currentId, seed);
      }
      tokenIds[i] = uint16(currentId);

      if (currentId % teamMintInterval == 0) mintToTeam = true;
    }

    // If stake then calc build array of owned mints (not kidnapped)
    if (commit.stake) {
      henHouse.addManyToHenHouse(_address, tokenIds);
    }
    if (mintToTeam) {
      _teamMint();
    }

    delete _mintCommits[_address][commitIdCur];
    delete _pendingCommitId[_address];
    emit MintRevealed(_address, numOfTotalMints);
  }

  function revealGen1(address _address) internal {
    uint16 commitIdCur = _pendingCommitId[_address];
    require(commitIdCur > 0, 'No pending commit');
    require(_commitRandoms[commitIdCur] > 0, 'Random seed not set');
    uint256 minted = farmAnimalsNFT.minted();
    MintCommit memory commit = _mintCommits[_address][commitIdCur];
    _pendingMintQty -= commit.quantity;

    uint256[] memory seeds = new uint256[](commit.quantity);

    RevealInfo memory revealInfo;

    revealInfo.startingTokenId = minted + 1;
    revealInfo.numOfTotalMints = commit.quantity;
    revealInfo.numToMints = commit.quantity;

    uint256 mintingId = revealInfo.startingTokenId;
    uint256 seed = _commitRandoms[commitIdCur];
    address recipient = _address;
    if (commit.stake) {
      recipient = address(henHouse);
    }

    for (uint256 i = 1; i <= commit.quantity; ) {
      seed = uint256(keccak256(abi.encode(seed, _address, commitIdCur, i)));

      IFarmAnimals.Kind kind = farmAnimalsNFT.pickKind(seed, 3);

      string memory kindText = kind == IFarmAnimals.Kind.HEN ? 'HEN' : kind == IFarmAnimals.Kind.COYOTE
        ? 'COYOTE'
        : 'ROOSTER';

      if (kind != IFarmAnimals.Kind.ROOSTER) {
        address theif = _selectRecipient(seed);

        if (kind == IFarmAnimals.Kind.HEN && seed % 100 < twinHenRate) {
          // Mint twins

          if (theif == tx.origin) {
            farmAnimalsNFT.mintTwins(seed, recipient, recipient);
          } else {
            farmAnimalsNFT.mintTwins(seed, recipient, theif);
          }
          revealInfo.numOfTotalMints++;
          revealInfo.numToMints--;
        } else if (theif == tx.origin) {
          // It's not stolen add seed
          seeds[i - 1] = seed;
        } else {
          // Stolen!

          (address _newRecipient, bool _applePieTaken) = _takeApplePie(theif, mintingId, seed);
          theif = _newRecipient;

          if (!_applePieTaken) {
            emit TokenKidnapped(tx.origin, theif, mintingId, kindText);
            if (kind == IFarmAnimals.Kind.HEN) {
              uint256 rescuedChance = ((seed >> 185) % 10);

              if (rescuedChance < 3) {
                address rescuer = henHouse.randomRoosterOwner(seed >> 128);

                if (rescuer != address(0x0)) {
                  emit TokenRescued(theif, rescuer, mintingId, kindText);
                  theif = rescuer;
                }
              }
            }
          }
          uint256[] memory stolenSeeds = new uint256[](1);
          stolenSeeds[0] = seed;
          farmAnimalsNFT.mintSeeds(theif, stolenSeeds);
          revealInfo.numToMints--;
        }
      } else {
        // It's a rooster which cannot be stolen, mint it to orginal minter
        seeds[i - 1] = seed;
      }
      mintingId++;
      unchecked {
        i++;
      }
    }

    if (revealInfo.numToMints > 0) {
      for (uint256 i = 1; i <= seeds.length; ) {
        unchecked {
          i++;
        }
      }
      farmAnimalsNFT.mintSeeds(recipient, seeds);
    }

    // Check numOfTotalMints are owned by current minter/revealer
    uint256 numToStake = 0;
    uint16[] memory tokenIdsToStake = new uint16[](revealInfo.numOfTotalMints);
    for (uint256 i = 1; i <= revealInfo.numOfTotalMints; ) {
      uint256 tokenId = revealInfo.startingTokenId + i - 1;

      if (tokenId % 100 == 0) {
        _givePlatinumEgg(tokenId);
      }

      if (commit.stake) {
        address currentOwner = farmAnimalsNFT.ownerOf(tokenId);

        if (currentOwner == address(henHouse)) {
          tokenIdsToStake[i - 1] = uint16(tokenId);
          numToStake++;
        } else {
          tokenIdsToStake[i - 1] = 0;
        }
      }
      unchecked {
        i++;
      }
    }

    // If stake then calc build array of owned mints (not kidnapped)
    if (commit.stake) {
      henHouse.addManyToHenHouse(_address, tokenIdsToStake);
    }
    _mintRevealDel(_address, commitIdCur, revealInfo.numOfTotalMints);
  }

  function _mintRevealDel(
    address _address,
    uint16 _commitIdCur,
    uint256 _numOfTotalMints
  ) internal {
    delete _mintCommits[_address][_commitIdCur];
    delete _pendingCommitId[_address];
    emit MintRevealed(_address, _numOfTotalMints);
  }

  function _teamMint() internal {
    uint256 minted = farmAnimalsNFT.minted();

    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();

    if (minted < gen0Supply) {
      uint256[] memory seeds = new uint256[](1);
      seeds[0] = uint256(keccak256(abi.encode(block.number, block.timestamp, owner())));

      farmAnimalsNFT.mintSeeds(owner(), seeds);
    }
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice Mint Platinum EggShop Token
   * @param _address Recipient address to receive Platinum EGG
   */

  function _awardPlatinumEgg(address _address) internal {
    eggShop.mint(platinumEggTypeId, 1, _address, uint256(0));
    emit EggShopAward(_address, platinumEggTypeId);
  }

  /**
   * @notice Check and then mint Platinum EggShop Token to a random previous minter
   * @param tokenId Current token ID
   */

  function _givePlatinumEgg(uint256 tokenId) internal {
    // If minting any increment of 100 then aware a platinum egg for gen 1+
    IEggShop.TypeInfo memory platinumTypeInfo = eggShop.getInfoForType(platinumEggTypeId);
    if ((platinumTypeInfo.mints + platinumTypeInfo.burns) < platinumTypeInfo.maxSupply) {
      uint256 tokenIdGift = tokenId - (randomizer.randomToken(tokenId) % 100);

      address tokenOwner = farmAnimalsNFT.ownerOf(tokenIdGift);
      if (tokenOwner == address(henHouse)) {
        IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenIdGift);
        _awardPlatinumEgg(stake.owner);
      } else {
        _awardPlatinumEgg(tokenOwner);
      }
    }
  }

  /**
   * @notice Selects a random coyote
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Coyote thief's owner)
   */
  function _selectRecipient(uint256 seed) internal view returns (address) {
    if (((seed >> 245) % 10) != 0) {
      return _msgSender();
    }

    address thief = henHouse.randomCoyoteOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0) || thief == _msgSender()) {
      return _msgSender();
    }
    return thief;
  }

  /**
   * @notice Transfer ETH and return the success status.
   * @dev This function only forwards 30,000 gas to the callee.
   * @param to Address for ETH to be send to
   * @param value Amount of ETH to send
   */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
    return success;
  }

  /**
   * @notice Determines if an apple pie should be taken instead of mint
   * @dev Internal only
   * @param _recipient The address to recieve the minted NFT
   * @param _tokenId Token ID of minted NFT
   * @param _seed The seed used to mint the NFT
   * @return bool applePieTaken, address recpient to recieve minted NFT (possibly different from _recipient)
   */
  function _takeApplePie(
    address _recipient,
    uint256 _tokenId,
    uint256 _seed
  ) internal returns (address, bool) {
    address recipient = _recipient;

    bool applePieTaken = false;
    if (eggShop.balanceOf(tx.origin, applePieTypeId) > 0) {
      // If the mint is going to be stolen, there's a 50% chance a coyote will prefer a apple pie over it
      if (_seed & 1 == 1) {
        eggShop.safeTransferFrom(tx.origin, recipient, applePieTypeId, 1, '');
        recipient = tx.origin;
        applePieTaken = true;

        emit ApplePieTaken(tx.origin, recipient, _tokenId);
      }
    }
    return (recipient, applePieTaken);
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @notice Get Pending Mint Amount regarding the address
   * address to get pending mint amount
   */

  function getPendingMint(address _address) external view returns (MintCommit memory) {
    require(_pendingCommitId[_address] != 0, 'No pending commits');
    return _mintCommits[_address][_pendingCommitId[_address]];
  }

  /**
   * @notice Make sure address has a Pending Mint.
   */

  function hasMintPending(address _address) external view returns (bool) {
    return _pendingCommitId[_address] != 0;
  }

  /**
   * @notice Make sure address can reveal a pending mint
   */

  function canReveal(address _address) external view returns (bool) {
    return _pendingCommitId[_address] != 0 && _commitRandoms[_pendingCommitId[_address]] > 0;
  }

  /**
   * @notice Get the current NFT Mint Price
   * it will return mint eth price or EGG price regarding presale and publicsale
   */

  function currentPriceToMint() public view returns (uint256) {
    uint256 minted = farmAnimalsNFT.minted();

    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    if (minted >= gen0Supply) {
      return mintCostEGG(minted + _pendingMintQty + 1);
    } else if (block.timestamp >= publicTime) {
      return publicFee;
    } else {
      return preSaleFee;
    }
  }

  /**
   * @notice Get number of NFTs _minter has minted via preSaleMint()
   * @param _minter address of minter to lookup
   */
  function getPreSaleMintRecord(address _minter) external view returns (uint256) {
    return preSaleMintRecords[_minter];
  }

  /**
   * @notice Get number of NFTs _minter has minted via preSaleMint()
   * @param _minter address of minter to lookup
   */
  function getPublicMintRecord(address _minter) external view returns (uint256) {
    return publicMintRecords[_minter];
  }

  /**
   * @return the cost for the current gen step
   */

  function mintCostEGG(uint256 tokenId) public view returns (uint256) {
    uint256 maxSupply = farmAnimalsNFT.maxSupply();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 gAmount = (maxSupply - gen0Supply) / 5;
    if (tokenId <= gen0Supply) return 0; // GEN 0
    if (tokenId <= (gAmount + gen0Supply)) return 24000 ether; // GEN 1
    if (tokenId <= (gAmount * 2) + gen0Supply) return 36000 ether; // GEN 2
    if (tokenId <= (gAmount * 3) + gen0Supply) return 48000 ether; // GEN 3
    if (tokenId <= (gAmount * 4) + gen0Supply) return 60000 ether; // GEN 4
    return maxEggCost; // GEN 5
  }

  /**
   * @notice Get current mint sale status
   */

  function getSaleStatus() external view returns (string memory) {
    if (paused() == true) {
      return 'paused';
    }
    if (block.timestamp >= publicTime) {
      uint256 minted = farmAnimalsNFT.minted();
      uint256 maxSupply = farmAnimalsNFT.maxSupply();
      uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
      uint256 gAmount = (maxSupply - gen0Supply) / 5;
      if (minted < gen0Supply) return 'GEN 0';
      if (minted <= (gAmount + gen0Supply)) return 'GEN 1';
      if (minted <= (gAmount * 2) + gen0Supply) return 'GEN 2';
      if (minted <= (gAmount * 3) + gen0Supply) return 'GEN 3';
      if (minted <= (gAmount * 4) + gen0Supply) return 'GEN 4';
      return 'GEN 5';
    } else if (block.timestamp < publicTime && block.timestamp >= allowListTime) {
      return 'allowlist';
    } else if (block.timestamp < allowListTime && block.timestamp >= preSaleTime) {
      return 'presale';
    } else {
      return 'soon';
    }
  }

  /**
   * @notice Get current mint status
   */

  function canMint() external view returns (bool) {
    if (paused() == true) {
      return false;
    }
    if (block.timestamp >= publicTime || block.timestamp >= preSaleTime) {
      return true;
    } else {
      return false;
    }
  }

  /**
   *   ██████  ██     ██ ███    ██ ███████ ██████
   *  ██    ██ ██     ██ ████   ██ ██      ██   ██
   *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
   *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
   *   ██████   ███ ███  ██   ████ ███████ ██   ██
   * This section will have all the internals set to onlyOwner
   */

  /**
   * @notice Set new EGG Max Mint amount
   * @param _amount max EGG amount
   */

  function setMaxEggCost(uint256 _amount) external onlyOwner {
    maxEggCost = _amount;
  }

  /**
   * @notice Mint via preSale merkle tree
   * @dev Only callable if caller is controller
   * @param _hash the merkle root hash value
   */

  function setPreSaleRoot(bytes32 _hash) external onlyOwner {
    preSaleRoot = _hash;
  }

  /**
   * @notice Mint via allowList merkle tree
   * @dev Only callable if caller is controller
   * @param _hash the merkle root hash value
   */

  function setAllowListRoot(bytes32 _hash) external onlyOwner {
    allowListRoot = _hash;
  }

  /**
   * @notice Allow the mintCommit feature
   */

  function setAllowCommits(bool allowed) external onlyOwner {
    allowCommits = allowed;
  }

  /**
   * @notice Allow the contract owner to set the pending mint quantity
   * @dev Only callable by owner
   * @param pendingQty Used to reset the pending quantity
   * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been
   *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
   * This function should not be called lightly, this will have negative consequences on the game.
   */
  function setPendingMintAmt(uint16 pendingQty) external onlyOwner {
    _pendingMintQty = pendingQty;
  }

  /**
   * @notice Set new public sale mint price
   * @param _fee eth price for the public mint sale
   */

  function setPreSaleFee(uint256 _fee) external onlyOwner {
    preSaleFee = _fee;
  }

  /**
   * @notice Set new public mint & stake sale mint price
   * @param _fee eth price for the public mint sale
   */

  function setPreSaleMintStakeFee(uint256 _fee) external onlyOwner {
    preSaleStakeFee = _fee;
  }

  /**
   * @notice Set new Presale TimeStamp
   * @dev Modifer to require msg.sender to be owner
   * @param _time Unix time to update new presale time
   */

  function setPreSaleTime(uint256 _time) external onlyOwner {
    preSaleTime = _time;
  }

  /**
   * @notice Set new Presale TimeStamp
   * @dev Modifer to require msg.sender to be owner
   * @param _time Unix time to update new presale time
   */

  function setAllowListTime(uint256 _time) external onlyOwner {
    allowListTime = _time;
  }

  /**
   * @notice Set new public sale mint price
   * @param _fee eth price for the public mint sale
   */

  function setPublicFee(uint256 _fee) external onlyOwner {
    publicFee = _fee;
  }

  /**
   * @notice Set new public mint & stake sale mint price
   * @param _fee eth price for the public mint sale
   */

  function setPublicMintStakeFee(uint256 _fee) external onlyOwner {
    publicStakeFee = _fee;
  }

  /**
   * @notice Set new Public Sale Time
   * @dev Modifer to require msg.sender to be owner
   * @param _time Unix time to update new public sale time
   */

  function setPublicSaleTime(uint256 _time) external onlyOwner {
    publicTime = _time;
  }

  /**
   * @notice Set Public sale max tx limit
   * @param _txLimit the max tokens per tx
   */

  function setPublicSaleMaxTx(uint256 _txLimit) external onlyOwner {
    publicMaxPerTx = _txLimit;
  }

  /**
   * @notice Set Team minting interal, this will mint an NFT to the team wallet. Only for Gen0 mints
   * @dev If set to say every 10, and the minter mints token IDs #8-11, then the theam will be minted token #12
   * @param _interval the team interval.
   */

  function setTeamInterval(uint256 _interval) external onlyOwner {
    teamMintInterval = _interval;
  }

  /**
   * @notice Allows owner to withdraw ETH funds to an address
   * @dev wraps _user in payable to fix address -> address payable
   * @param to Address for ETH to be send to
   */

  function withdraw(address payable to) external onlyOwner {
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 minted = farmAnimalsNFT.minted();
    if (liqudityAlreadyPaid < gen0Supply) {
      uint256 tokenCountToBeAdded = 1;
      if (minted <= gen0Supply) {
        tokenCountToBeAdded = minted - liqudityAlreadyPaid;
      } else {
        tokenCountToBeAdded = gen0Supply - liqudityAlreadyPaid;
      }
      liqudityAlreadyPaid += tokenCountToBeAdded;
      uint256 ethToBeAdded = tokenCountToBeAdded * 0.002 ether;
      uint256 ethToWidraw = address(this).balance - ethToBeAdded;
      uint256 eggToBeAdded = tokenCountToBeAdded * 1000 ether;
      // eggToken.mint(address(this), eggToBeAdded);
      eggToken.addLiquidityETH{ value: ethToBeAdded }(eggToBeAdded, ethToBeAdded);
      require(_safeTransferETH(to, ethToWidraw));
    } else {
      require(_safeTransferETH(to, address(this).balance));
    }
  }

  /**
   * @notice Allows owner to withdraw any accident tokens transferred to contract
   * @param _tokenContract Address for the token
   * @param to Address for token to be send to
   * @param amount Amount of token to send
   */
  function withdrawToken(
    address _tokenContract,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);
    tokenContract.transfer(to, amount);
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
   * @notice Seed the current commit id so that pending commits can be revealed
   * @dev Only callable by existing controller
   * @param seed Seed to use iin for current commits
   */

  function addCommitRandom(uint256 seed) external onlyController {
    _commitRandoms[_commitId] = seed;
    _commitId += 1;
  }

  /**
   * @notice This is for the randomizer to check if update is needed, saves LINK tokens
   * @dev Only callable by existing controller
   */

  function commitRandomNeeded() external view onlyController returns (bool) {
    bool needsUpdate = _commitId == _lastUsedCommitId;

    return needsUpdate;
  }

  /**
   * @notice Remove all pending mints by address
   * @dev Only callable by existing controller
   */

  function deleteCommit(address _address) external onlyController {
    uint16 commitIdCur = _pendingCommitId[_address];
    require(commitIdCur > 0, 'No pending commit');
    delete _mintCommits[_address][commitIdCur];
    delete _pendingCommitId[_address];
  }

  /**
   * @notice Reveal the pending mints by address
   */

  function forceRevealCommitGen0(address _address) external onlyController {
    revealGen0(_address);
  }

  /**
   * @notice Reveal the pending mints by address
   */

  function forceRevealCommitGen1(address _address) external onlyController {
    revealGen1(_address);
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice Allows controller to check if there are any pending mints
   * @dev Only callable by existing controller
   */
  function getPendingMintQty() external view onlyController returns (uint16) {
    return _pendingMintQty;
  }

  /**
   * @notice Set multiple contract addresses
   * @dev Only callable by an existing controller
	 * @param _eggCitement Address of eggCitement contract
   * @param _eggShop Address of eggShop contract
   * @param _eggToken Address of eggToken contract
   * @param _farmAnimalsNFT Address of farmAnimals contract
   * @param _henHouse Address of henHouse contract

   * @param _randomizer Address of randomizer contract
   */

  function setExtContracts(
    address _eggCitement,
    address _eggShop,
    address _eggToken,
    address _farmAnimalsNFT,
    address _henHouse,
    address _randomizer
  ) external onlyController {
    eggCitement = IEggCitement(_eggCitement);
    eggShop = IEggShop(_eggShop);
    eggToken = IEGGToken(_eggToken);
    farmAnimalsNFT = IFarmAnimals(_farmAnimalsNFT);
    henHouse = IHenHouse(_henHouse);
    randomizer = IRandomizer(_randomizer);
  }

  /**
   * @notice Enables controller to pause / unpause contract
   */
  function setPaused(bool _paused) external onlyController {
    if (_paused) _pause();
    else _unpause();
    emit SaleStatusUpdated(
      preSaleTime,
      allowListTime,
      preSaleFee,
      preSaleStakeFee,
      publicTime,
      publicFee,
      publicStakeFee
    );
  }
}
