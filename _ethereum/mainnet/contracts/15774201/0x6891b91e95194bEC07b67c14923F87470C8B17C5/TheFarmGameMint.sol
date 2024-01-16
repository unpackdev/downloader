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

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./ERC165Storage.sol";
import "./IEGGToken.sol";
import "./IEggShop.sol";
import "./IFarmAnimals.sol";
import "./IHenHouse.sol";
import "./IRandomizer.sol";
import "./ISpecialMint.sol";
import "./SafeMath.sol";

contract TheFarmGameMint is Ownable, ERC165Storage, ReentrancyGuard, Pausable {
  using SafeMath for uint256;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  event MintCommitted(address indexed owner, uint256 indexed quantity);
  event MintRevealed(address indexed owner, uint256 indexed quantity);
  event EggShopAward(address indexed recipient, uint16 indexed typeId);
  event SaleStatusUpdated(
    uint256 preSaleTime,
    uint256 allowListTime,
    uint256 preSaleFee,
    uint256 preSaleStakeFee,
    uint256 publicSaleTime,
    uint256 publicSaleFee,
    uint256 publicStakeFee
  );
  event InitializedContract(address thisContract);

  // PreSale
  uint256 public preSaleTime = 1666105200; // Thursday, October 18, 2022 3:00 PM UTC / 11:00 AM EST

  uint256 public preSaleFee = 0.049 ether;
  uint256 public preSaleMaxQty = 4;
  uint256 public preSaleStakeFee = 0.025 ether;
  bytes32 public preSaleRoot; // Merkel root for preSale

  // Allow List
  uint256 public allowListTime = 1666110600; // Thursday, October 18, 2022 4:30 PM UTC / 12:30 PM EST
  bytes32 public allowListRoot; // Merkel root for allow list sale

  mapping(address => uint16) private mintRecords; // Address => tokenIDs, track number of mints during presale

  // Public Sale Gen 0
  uint256 public publicTime = 1666117800; // Thursday, October 18, 2022 6:30 PM UTC / 2:30 PM EST
  uint256 public publicFee = 0.049 ether;
  uint256 public publicStakeFee = 0.035 ether;
  uint256 public publicMaxPerTx = 5;

  uint256 public teamMintEvery = 25; // Auto mints Gen0 token to team every X

  // Gen 1+
  uint256 private maxEggCost = 72000 ether; // max EGG cost

  // Mint Commit/Reveal
  struct MintCommit {
    bool stake;
    uint16 quantity;
  }
  mapping(address => mapping(uint16 => MintCommit)) private _mintCommits; // address -> commit # -> commits
  mapping(address => uint16) private _pendingCommitId; // address -> commit num of commit need revealed for account
  mapping(uint16 => uint256) private _commitRandoms; // commit # -> offchain random
  uint16 private _commitId = 1;
  uint16 private pendingMintAmt;
  bool public allowCommits = false;

  // Auto-liquidity
  uint256 liqudityAlreadyPaid = 0; // Count of tokens that liquidity is already paid for

  // Admin
  mapping(address => bool) public controllers; // address => can call allowedToCallFunctions

  // LastWrite security
  struct LastWrite {
    uint64 time;
    uint64 blockNum;
  }

  mapping(address => LastWrite) private _lastWrite;

  // Egg shop type IDs
  uint16 public applePieTypeId = 1;
  uint16 public platinumEggTypeId = 5;

  // Interfaces
  IRandomizer public randomizer;
  IHenHouse public henHouse; // reference to the Hen House for choosing random Coyote thieves
  IEGGToken public eggToken; // reference to EGG for burning on mint
  IFarmAnimals public farmAnimalsNFT; // reference to NFT collection
  IEggShop public eggShop; // reference to eggShop collection
  ISpecialMint public specialMint; // reference to special mint

  /** MODIFIERS */

  /**
   * @dev Modifer to require contract to be set before a transfer can happen
   */

  modifier requireContractsSet() {
    require(
      address(eggToken) != address(0) &&
        address(farmAnimalsNFT) != address(0) &&
        address(henHouse) != address(0) &&
        address(eggShop) != address(0) &&
        address(randomizer) != address(0),
      'Contracts not set'
    );
    _;
  }

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
  constructor(
    IEGGToken _eggToken,
    IEggShop _eggShop,
    IFarmAnimals _farmAnimalsNFT,
    IHenHouse _henHouse,
    IRandomizer _randomizer,
    ISpecialMint _specialMint
  ) {
    eggToken = _eggToken;
    eggShop = _eggShop;
    farmAnimalsNFT = _farmAnimalsNFT;
    henHouse = _henHouse;
    randomizer = _randomizer;
    specialMint = _specialMint;
    controllers[_msgSender()] = true;

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
   * @notice Mint public sale Gen 0 for ETH
   * @dev Gen 0 mint a token - ~87% Hen, 10% Coyotes, 3% Rooster
   * @param quantity number of NFTs to mint in this transaction
   * @param stake stake NFTs upon minting
   */

  function mint(uint256 quantity, bool stake) external payable whenNotPaused nonReentrant {
    require(tx.origin == _msgSender() || controllers[_msgSender()], 'Only EOA or controllers');
    require(block.timestamp >= publicTime, 'Public sale not yet started');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();

    require(minted <= gen0Supply, 'All paid tokens minted');
    require(minted + quantity <= gen0Supply, 'Qty greater than available tokens');
    require(quantity > 0 && quantity <= publicMaxPerTx, 'Invalid mint qty');

    LastWrite storage lw = _lastWrite[tx.origin];

    uint256 totalEthCost = 0;
    uint16 startingTokenId = minted + 1;
    uint256 numOfMints = 0;

    for (uint256 i = 0; i < quantity; i++) {
      minted++; // current ID being minted

      uint256 seed = randomizer.randomToken(minted);

      // Gen0 Price
      if (stake) {
        totalEthCost = publicStakeFee * quantity;
      } else {
        totalEthCost = publicFee * quantity;
      }

      if (!stake) {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(_msgSender(), seed);
        numOfMints += newTokenIds.length;
      } else {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(address(henHouse), seed);
        numOfMints += newTokenIds.length;
      }
    }
    require(msg.value >= totalEthCost, 'Invalid ETH amount');

    uint16[] memory tokenIds = new uint16[](numOfMints);
    for (uint16 i = 0; i < numOfMints; i++) {
      tokenIds[i] = startingTokenId + i;
    }
    farmAnimalsNFT.updateOriginAccess(tokenIds);

    if (stake) {
      henHouse.addManyToHenHouse(_msgSender(), tokenIds);
    }

    lw.time = uint64(block.timestamp);
    lw.blockNum = uint64(block.number);
    teamMint(startingTokenId, numOfMints);
  }

  function _mintStake(
    address recipient,
    uint256 quantity,
    bool stake,
    uint16 minted
  ) internal {
    uint16 startingTokenId = minted + 1;
    uint256 numOfMints = 0;
    for (uint256 i = 0; i < quantity; i++) {
      minted++;
      uint256 seed = randomizer.randomToken(minted);
      if (!stake) {
        farmAnimalsNFT.mint(recipient, seed);
      } else {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(address(henHouse), seed);
        numOfMints = numOfMints + newTokenIds.length;
      }
    }
    if (stake) {
      uint16[] memory tokenIds = new uint16[](numOfMints);
      for (uint16 i = 0; i < numOfMints; i++) {
        tokenIds[i] = startingTokenId + i;
      }
      henHouse.addManyToHenHouse(recipient, tokenIds);
    }
    teamMint(startingTokenId, numOfMints);
  }

  function teamMint(uint16 startingTokenId, uint256 numOfMints) internal {
    for (uint16 i = 0; i < numOfMints; i++) {
      if ((startingTokenId + i) % teamMintEvery == 0) {
        uint256 seed = randomizer.randomToken(startingTokenId + i + block.timestamp);
        farmAnimalsNFT.mint(owner(), seed);
      }
    }
  }

  /**
   * @notice Mint via preSale merkle tree for ETH
   * @dev Only callable if public sale has not started && contracts have been set
   * @param quantity number of NFTs to mint in this transaction
   * @param stake stake NFTs upon minting
   * @param merkleProof merkle proof for msg.sender
   */
  function preSaleMint(
    uint256 quantity,
    bool stake,
    bytes32[] memory merkleProof
  ) external payable whenNotPaused requireContractsSet {
    require(tx.origin == _msgSender() || controllers[_msgSender()], 'Only EOA or controllers');
    require(block.timestamp >= preSaleTime && block.timestamp < publicTime, 'Pre-sale not running');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    require(minted < gen0Supply, 'All tokens minted');
    require(minted + quantity <= gen0Supply, 'Qty exceeds max supply');

    bytes32 node = keccak256(abi.encode(msg.sender));
    if (block.timestamp >= preSaleTime && block.timestamp < allowListTime) {
      require(MerkleProof.verify(merkleProof, preSaleRoot, node), 'Minters address not eligible for preSale mint');
    } else if (block.timestamp >= allowListTime) {
      require(MerkleProof.verify(merkleProof, allowListRoot, node), 'Minters address not eligible for allow list mint');
    }

    require(mintRecords[_msgSender()] + quantity <= preSaleMaxQty, 'Mint would exceed minters address max allowed');

    mintRecords[_msgSender()] = mintRecords[_msgSender()] + uint16(quantity);

    // Price Calc
    uint256 totalEthCost = 0;
    if (stake) {
      totalEthCost = preSaleStakeFee * quantity;
    } else {
      totalEthCost = preSaleFee * quantity;
    }

    require(msg.value >= totalEthCost, 'Payment amount is not correct.');

    _mintStake(_msgSender(), quantity, stake, minted);
  }

  /**
   * @notice Get number of NFTs _minter has minted via preSaleMint()
   * @param _minter address of minter to lookup
   */
  function getMintRecord(address _minter) external view returns (uint256) {
    return mintRecords[_minter];
  }

  /**
   * Mint Commit/Reveal
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
   * @notice Seed the current commit id so that pending commits can be revealed
   */

  function addCommitRandom(uint256 seed) external onlyController {
    _commitRandoms[_commitId] = seed;
    _commitId += 1;
  }

  /**
   * @notice Remove all pending mints by address
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

  function forceRevealCommit(address _address) external onlyController {
    reveal(_address);
  }

  /**
   * @dev Initiate the start of a mint. This action burns EGG, as the intent of committing is that you cannot back out once you've started.
   * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
   * commit was added to. */
  function mintCommit(uint256 quantity, bool stake) external whenNotPaused nonReentrant {
    require(allowCommits, 'Adding commits disallowed');
    require(tx.origin == _msgSender(), 'Only EOA');
    require(_pendingCommitId[_msgSender()] == 0, 'Already have pending mints');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 maxSupply = farmAnimalsNFT.maxSupply();
    require(minted >= gen0Supply, 'Gen 0 not fully minted');
    require(minted + pendingMintAmt + quantity <= maxSupply, 'All tokens minted');
    require(quantity > 0 && quantity <= 10, 'Invalid mint qty');

    uint256 totalEggCost = 0;
    // Loop through the quantity of
    for (uint256 i = 1; i <= quantity; i++) {
      totalEggCost += mintCostEGG(minted + pendingMintAmt + i);
    }
    if (totalEggCost > 0) {
      eggToken.burn(_msgSender(), totalEggCost);
    }
    uint16 amt = uint16(quantity);
    _mintCommits[_msgSender()][_commitId] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = _commitId;
    pendingMintAmt += amt;
    emit MintCommitted(_msgSender(), quantity);
  }

  /**
   * @dev Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
   * the user is pending for has been assigned a random seed. */
  function mintReveal() external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), 'Only EOA');
    reveal(_msgSender());
  }

  function reveal(address _address) internal {
    uint16 commitIdCur = _pendingCommitId[_address];

    require(commitIdCur > 0, 'No pending commit');
    require(_commitRandoms[commitIdCur] > 0, 'Random seed not set');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    MintCommit memory commit = _mintCommits[_address][commitIdCur];
    pendingMintAmt -= commit.quantity;

    uint16 startingTokenId = minted + 1;
    uint256 numOfMints = 0;

    uint256 seed = _commitRandoms[commitIdCur];
    for (uint256 k = 0; k < commit.quantity; k++) {
      minted++;

      seed = uint256(keccak256(abi.encode(seed, _address)));
      address recipient = _selectRecipient(seed, minted, gen0Supply);
      if (!commit.stake || recipient != _address) {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(recipient, seed);
        numOfMints = numOfMints + newTokenIds.length;
      } else {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(address(henHouse), seed);
        numOfMints = numOfMints + newTokenIds.length;
      }
    }

    uint16[] memory tokenIds = new uint16[](numOfMints);
    uint256 numOfOwned = 0;
    for (uint16 i = 0; i < numOfMints; i++) {
      uint16 tokenId = startingTokenId + i;
      // Add tokenIds to tokenIds[] for updateOriginAccess
      tokenIds[i] = startingTokenId + i;

      address currentOwner = farmAnimalsNFT.ownerOf(tokenId);
      if (currentOwner == address(henHouse)) {
        numOfOwned++;
      }
    }

    farmAnimalsNFT.updateOriginAccess(tokenIds);

    // If stake then calc build array of owned mints (not kidnapped)
    if (commit.stake) {
      uint16[] memory tokenIdsToStake = new uint16[](numOfOwned);
      uint16 nIndex = 0;
      for (uint16 i = 0; i < numOfMints; i++) {
        uint16 tokenId = startingTokenId + i;
        address currentOwner = farmAnimalsNFT.ownerOf(tokenId);
        if (currentOwner == address(henHouse)) {
          tokenIdsToStake[nIndex] = tokenId;
          nIndex++;
        }
      }

      henHouse.addManyToHenHouse(_address, tokenIdsToStake);
    }

    // If minting any incement of 100 then aware a platinum egg for gen 1+
    for (uint16 i = 0; i < numOfMints; i++) {
      uint16 tokenId = startingTokenId + i;
      if (tokenId > gen0Supply && tokenId % 100 == 0) {
        IEggShop.TypeInfo memory platinumTypeInfo = eggShop.getInfoForType(platinumEggTypeId);
        if ((platinumTypeInfo.mints + platinumTypeInfo.burns) < platinumTypeInfo.maxSupply) {
          uint256 tokenIdGift = uint256(tokenId).sub(randomizer.randomToken(tokenId).mod(100));
          address tokenOwner = farmAnimalsNFT.ownerOf(tokenIdGift);
          if (tokenOwner == address(henHouse)) {
            IHenHouse.Stake memory stake = henHouse.getStakeInfo(uint16(tokenIdGift));
            _awardPlatinumEgg(stake.owner);
          } else {
            _awardPlatinumEgg(tokenOwner);
          }
        }
      }
    }

    delete _mintCommits[_address][commitIdCur];
    delete _pendingCommitId[_address];
    emit MintRevealed(_address, numOfMints);
  }

  /**
   * End Randomenizer calls
   */

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
   * @param tokenOwner Recipient address to receive Platinum EGG
   */

  function _awardPlatinumEgg(address tokenOwner) internal {
    eggShop.mint(platinumEggTypeId, 1, tokenOwner, uint256(0));
    emit EggShopAward(tokenOwner, uint16(platinumEggTypeId));
  }

  /**
   * The first Gen0 (ETH purchases) go to the minter
   * The remaining have a 10% chance to be given to a random staked coyote
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Coyote thief's owner)
   */
  function _selectRecipient(
    uint256 seed,
    uint256 minted,
    uint256 gen0Supply
  ) internal view returns (address) {

    if (minted <= gen0Supply || ((seed >> 245) % 10) != 0) return _msgSender();

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
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @notice Get the current NFT Mint Price
   * it will return mint eth price or EGG price regarding presale and publicsale
   */

  function currentPriceToMint() public view returns (uint256) {
    uint16 minted = farmAnimalsNFT.minted();

    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    if (minted >= gen0Supply) {
      return mintCostEGG(minted + pendingMintAmt + 1);
    } else if (block.timestamp >= publicTime) {
      return publicFee;
    } else {
      return preSaleFee;
    }
  }

  /**
   * @return the cost for the current gen step
   */

  function mintCostEGG(uint256 tokenId) public view returns (uint256) {
    uint256 maxSupply = farmAnimalsNFT.maxSupply();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 gAmount = (maxSupply.sub(gen0Supply)).div(5);
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
    if (block.timestamp >= publicTime) {
      if (paused() == true) {
        return 'paused';
      }
      uint16 minted = farmAnimalsNFT.minted();
      uint256 maxSupply = farmAnimalsNFT.maxSupply();
      uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
      uint256 gAmount = (maxSupply.sub(gen0Supply)).div(5);
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
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyController {
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

  /**
   * @notice Set new EGG Max Mint amount
   * @param _amount max EGG amount
   */

  function setMaxEggCost(uint256 _amount) external requireContractsSet onlyOwner {
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

  /** Allow the contract owner to set the pending mint amount.
   * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been
   *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
   * This function should not be called lightly, this will have negative consequences on the game.
   */
  function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
    pendingMintAmt = uint16(pendingAmt);
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
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
    preSaleStakeFee = _fee;
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
   * @notice Set Team Reserve
   * @param _qty the team reserve quantity
   */

  function setTeamReserve(uint256 _qty) external onlyOwner {
    teamMintEvery = _qty;
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
      uint256 tokenCountToBeAdded = 0;
      if (minted <= gen0Supply) {
        tokenCountToBeAdded = minted - liqudityAlreadyPaid;
      } else {
        tokenCountToBeAdded = gen0Supply - liqudityAlreadyPaid;
      }
      liqudityAlreadyPaid += tokenCountToBeAdded;
      uint256 ethToBeAdded = tokenCountToBeAdded * 0.0025 ether;
      uint256 ethToWidraw = address(this).balance.sub(ethToBeAdded);
      uint256 eggToBeAdded = tokenCountToBeAdded * 10000 ether;
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
}
