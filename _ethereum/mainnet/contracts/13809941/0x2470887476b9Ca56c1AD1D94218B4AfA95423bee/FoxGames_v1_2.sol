/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

import "./IFoxGame.sol";
import "./IFoxGameCarrot.sol";
import "./IFoxGameCrown.sol";
import "./IFoxGameNFT.sol";

contract FoxGames_v1_2 is IFoxGame, OwnableUpgradeable, IERC721ReceiverUpgradeable,
                    PausableUpgradeable, ReentrancyGuardUpgradeable {
  using ECDSAUpgradeable for bytes32; // signature verification helpers
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; // iterable staked tokens

  /****
   * Thanks for checking out our contracts.
   * If you're interested in working with us, you can find us on
   * discord (https://discord.gg/foxgame). We also have a bug bounty
   * program and are available at @officialfoxgame or bugs@fox.game.
   ***/

  // Maximum advantage score for both foxes and hunters
  uint8 public constant MAX_ADVANTAGE = 8;

  // Foxes take a 20% tax on all rabbiot $CARROT claimed
  uint8 public constant RABBIT_CLAIM_TAX_PERCENTAGE = 20;

  // Hunters have a 5% chance of stealing a fox as it unstakes
  uint8 private hunterStealFoxProbabilityMod;

  // Cut between hunters and foxes
  uint8 private hunterTaxCutPercentage;

  // Total hunter marksman scores staked
  uint16 public totalMarksmanPointsStaked;

  // Total fox cunning scores staked
  uint16 public totalCunningPointsStaked;

  // Number of Rabbit staked
  uint32 public totalRabbitsStaked;

  // Number of Foxes staked
  uint32 public totalFoxesStaked;

  // Number of Hunters staked
  uint32 public totalHuntersStaked;

  // The last time $CARROT was claimed
  uint48 public lastClaimTimestamp;

  // Rabbits must have 2 days worth of $CARROT to unstake or else it's too cold
  uint48 public constant RABBIT_MINIMUM_TO_EXIT = 2 days;

  // There will only ever be (roughly) 2.5 billion $CARROT earned through staking
  uint128 public constant MAXIMUM_GLOBAL_CARROT = 2500000000 ether;

  // amount of $CARROT earned so far
  uint128 public totalCarrotEarned;

  // Collected rewards before any foxes staked
  uint128 public unaccountedFoxRewards;

  // Collected rewards before any foxes staked
  uint128 public unaccountedHunterRewards;

  // Amount of $CARROT due for each cunning point staked
  uint128 public carrotPerCunningPoint;

  // Amount of $CARROT due for each marksman point staked
  uint128 public carrotPerMarksmanPoint;

  // Rabbit earn 10000 $CARROT per day
  uint128 public constant RABBIT_EARNING_RATE = 115740740740740740; // 10000 ether / 1 days;

  // Hunters earn 20000 $CARROT per day
  uint128 public constant HUNTER_EARNING_RATE = 231481481481481470; // 20000 ether / 1 days;

  // Staking state for both time-based and point-based rewards
  struct TimeStake { uint16 tokenId; uint48 time; address owner; }
  struct EarningStake { uint16 tokenId; uint128 earningRate; address owner; }

  // Events
  event TokenStaked(string kind, uint16 tokenId, address owner);
  event TokenUnstaked(string kind, uint16 tokenId, address owner, uint128 earnings);
  event FoxStolen(uint16 foxTokenId, address thief, address victim);

  // Signature to prove membership and randomness
  address private signVerifier;

  // External contract reference
  IFoxGameNFT private foxNFT;
  IFoxGameCarrot private foxCarrot;

  // Staked rabbits
  mapping(uint16 => TimeStake) public rabbitStakeByToken;

  // Staked foxes
  mapping(uint8 => EarningStake[]) public foxStakeByCunning; // foxes grouped by cunning
  mapping(uint16 => uint16) public foxHierarchy; // fox location within cunning group

  // Staked hunters
  mapping(uint16 => TimeStake) public hunterStakeByToken;
  mapping(uint8 => EarningStake[]) public hunterStakeByMarksman; // hunter grouped by markman
  mapping(uint16 => uint16) public hunterHierarchy; // hunter location within marksman group

  // FoxGame membership date
  mapping(address => uint48) public membershipDate;
  mapping(address => uint32) public memberNumber;
  event MemberJoined(address member, uint32 memberCount);
  uint32 public membershipCount;

  // External contract reference
  IFoxGameNFT private foxNFTGen1;

  // Mapping for staked tokens
  mapping(address => EnumerableSetUpgradeable.UintSet) private _stakedTokens;

  // Bool to store staking data
  bool private _storeStaking;

  // Use seed instead
  uint256 private _seed;

  // Reference to phase 2 utility token
  IFoxGameCrown private foxCrown;

  // amount of $CROWN earned so far
  uint128 public totalCrownEarned;

  // Cap CROWN earnings after 2.5 billion has been distributed
  uint128 public constant MAXIMUM_GLOBAL_CROWN = 2500000000 ether;

  // Entropy storage for future events that require randomness (claim, unstake).
  // Address => OP (claim/unstake) => TokenID => BlockNumber
  mapping(address => mapping(uint8 => mapping(uint16 => uint32))) private _stakeClaimBlock;

  // Op keys for Entropy storage
  uint8 private constant UNSTAKE_AND_CLAIM_IDX = 0;
  uint8 private constant CLAIM_IDX = 1;

  // Cost of a barrel in CARROT
  uint256 public barrelPrice;

  // Track account purchase of barrels
  mapping(address => uint48) private barrelPurchaseDate;

  // Barrel event purchase
  event BarrelPurchase(address account, uint256 price, uint48 timestamp);

  // Date when corruption begins to spread... 2 things happen:
  // 1. Carrot begins to burning
  // 2. Game risks go up
  uint48 public corruptionStartDate;

  // The last time $CROWN was claimed
  uint48 public lastCrownClaimTimestamp;

  // Phase 2 start date with 3 meanings:
  // - the date carrot will no long accrue rewards
  // - the date crown will start acruing rewards
  // - the start of a 24-hour countdown for corruption
  uint48 public divergenceTime;

  // Corruption percent rate per second
  uint128 public constant CORRUPTION_BURN_PERCENT_RATE = 1157407407407; // 10% burned per day

  // Events for token claiming in phase 2
  event ClaimCarrot(IFoxGameNFT.Kind, uint16 tokenId, address owner, uint128 reward, uint128 corruptedCarrot);
  event CrownClaimed(string kind, uint16 tokenId, address owner, bool unstake, uint128 reward, uint128 tax, bool elevatedRisk);

  // Store a bool per token to ensure we dont double claim carrot
  mapping(uint16 => bool) private tokenCarrotClaimed;

  // < Placeholder >
  uint48 private ___;

  // Amount of $CROWN due for each cunning point staked
  uint128 public crownPerCunningPoint;

  // Amount of $CROWN due for each marksman point staked
  uint128 public crownPerMarksmanPoint;

  // Indicator of which users are still grandfathered into the ground floor of
  // $CROWN earnings.
  mapping(uint16 => bool) private hasRecentEarningPoint;

  /**
   * Set the date for phase 2 launch.
   * @param timestamp Timestamp
   */
  function setDivergenceTime(uint48 timestamp) external onlyOwner {
    divergenceTime = timestamp;
  }

  /**
   * Init contract upgradability (only called once).
   */
  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    hunterStealFoxProbabilityMod = 20; // 100/5=20
    hunterTaxCutPercentage = 30; // whole number %

    // Pause staking on init
    _pause();
  }

  /**
   * Returns the corruption start date.
   */
  function getCorruptionEnabled() external view returns (bool) {
    return corruptionStartDate != 0 && corruptionStartDate < block.timestamp;
  }

  /**
   * Sets the date when corruption will begin to destroy carrot.
   * @param timestamp time.
   */
  function setCorruptionStartTime(uint48 timestamp) external onlyOwner {
    corruptionStartDate = timestamp;
  }

  /**
   * Helper functions for validating random seeds.
   */
  function getClaimSigningHash(address recipient, uint16[] calldata tokenIds, bool unstake, uint32[] calldata blocknums, uint256[] calldata seeds) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(recipient, tokenIds, unstake, blocknums, seeds));
  }
  function getMintSigningHash(address recipient, uint8 token, uint32 blocknum, uint256 seed) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(recipient, token, blocknum, seed));
  }
  function isValidMintSignature(address recipient, uint8 token, uint32 blocknum, uint256 seed, bytes memory sig) public view returns (bool) {
    bytes32 message = getMintSigningHash(recipient, token, blocknum, seed).toEthSignedMessageHash();
    return ECDSAUpgradeable.recover(message, sig) == signVerifier;
  }
  function isValidClaimSignature(address recipient, uint16[] calldata tokenIds, bool unstake, uint32[] calldata blocknums, uint256[] calldata seeds, bytes memory sig) public view returns (bool) {
    bytes32 message = getClaimSigningHash(recipient, tokenIds, unstake, blocknums, seeds).toEthSignedMessageHash();
    return ECDSAUpgradeable.recover(message, sig) == signVerifier;
  }

  /**
   * Set the purchase price of Barrels.
   * @param price Cost in CARROT
   */
  function setBarrelPrice(uint256 price) external onlyOwner {
    barrelPrice = price;
  }

  /**
   * Allow accounts to purchase barrels using CARROT.
   */
  function purchaseBarrel() external whenNotPaused nonReentrant {
    require(tx.origin == msg.sender, "eos");
    require(barrelPurchaseDate[msg.sender] == 0, "one barrel per account");

    barrelPurchaseDate[msg.sender] = uint48(block.timestamp);
    foxCarrot.burn(msg.sender, barrelPrice);
    emit BarrelPurchase(msg.sender, barrelPrice, uint48(block.timestamp));
  }

  /**
   * Exposes user barrel purchase date.
   * @param account Account to query.
   */
  function ownsBarrel(address account) external view returns (bool) {
    return barrelPurchaseDate[account] != 0;
  }

  /**
   * Return the appropriate contract interface for token.
   */
  function getTokenContract(uint16 tokenId) private view returns (IFoxGameNFT) {
    return tokenId <= 10000 ? foxNFT : foxNFTGen1;
  }

  /**
   * Helper method to fetch rotating entropy used to generate random seeds off-chain.
   * @param tokenIds List of token IDs.
   * @return entropies List of stored blocks per token.
   */
  function getEntropies(address recipient, uint16[] calldata tokenIds) external view returns (uint32[2][] memory entropies) {
    require(tx.origin == msg.sender, "eos");

    entropies = new uint32[2][](tokenIds.length);
    for (uint8 i; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];
      entropies[i] = [
        _stakeClaimBlock[recipient][UNSTAKE_AND_CLAIM_IDX][tokenId],
        _stakeClaimBlock[recipient][CLAIM_IDX][tokenId]
      ];
    }
  }

  /**
   * Adds Rabbits, Foxes and Hunters to their respective safe homes.
   * @param account the address of the staker
   * @param tokenIds the IDs of the Rabbit and Foxes to stake
   */
  function stakeTokens(address account, uint16[] calldata tokenIds) external whenNotPaused nonReentrant _updateEarnings {
    require((account == msg.sender && tx.origin == msg.sender) || msg.sender == address(foxNFTGen1), "not approved");
    
    IFoxGameNFT nftContract;
    uint32 blocknum = uint32(block.number);
    mapping(uint16 => uint32) storage senderUnstakeBlock = _stakeClaimBlock[msg.sender][UNSTAKE_AND_CLAIM_IDX];
    for (uint16 i; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];

      // Thieves abound and leave minting gaps
      if (tokenId == 0) {
        continue;
      }

      // Set unstake entropy
      senderUnstakeBlock[tokenId] = blocknum;

      // Add to respective safe homes
      nftContract = getTokenContract(tokenId);
      IFoxGameNFT.Kind kind = _getKind(nftContract, tokenId);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        _addRabbitToKeep(account, tokenId);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        _addFoxToDen(nftContract, account, tokenId);
      } else { // HUNTER
        _addHunterToCabin(nftContract, account, tokenId);
      }

      // Transfer into safe house
      if (msg.sender != address(foxNFTGen1)) { // dont do this step if its a mint + stake
        require(nftContract.ownerOf(tokenId) == msg.sender, "not owner");
        nftContract.transferFrom(msg.sender, address(this), tokenId);
      }
    }
  }

  /**
   * Adds Rabbit to the Keep.
   * @param account the address of the staker
   * @param tokenId the ID of the Rabbit to add to the Barn
   */
  function _addRabbitToKeep(address account, uint16 tokenId) internal {
    rabbitStakeByToken[tokenId] = TimeStake({
      owner: account,
      tokenId: tokenId,
      time: uint48(block.timestamp)
    });
    totalRabbitsStaked += 1;
    emit TokenStaked("RABBIT", tokenId, account);
  }

  /**
   * Add Fox to the Den.
   * @param account the address of the staker
   * @param tokenId the ID of the Fox
   */
  function _addFoxToDen(IFoxGameNFT nftContract, address account, uint16 tokenId) internal {
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    totalCunningPointsStaked += cunning;
    // Store fox by rating
    foxHierarchy[tokenId] = uint16(foxStakeByCunning[cunning].length);
    // Add fox to their cunning group
    foxStakeByCunning[cunning].push(EarningStake({
      owner: account,
      tokenId: tokenId,
      earningRate: crownPerCunningPoint
    }));
    // Phase 2 - Mark earning point as valid
    hasRecentEarningPoint[tokenId] = true;
    totalFoxesStaked += 1;
    emit TokenStaked("FOX", tokenId, account);
  }

  /**
   * Adds Hunter to the Cabin.
   * @param account the address of the staker
   * @param tokenId the ID of the Hunter
   */
  function _addHunterToCabin(IFoxGameNFT nftContract, address account, uint16 tokenId) internal {
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    totalMarksmanPointsStaked += marksman;
    // Store hunter by rating
    hunterHierarchy[tokenId] = uint16(hunterStakeByMarksman[marksman].length);
    // Add hunter to their marksman group
    hunterStakeByMarksman[marksman].push(EarningStake({
      owner: account,
      tokenId: tokenId,
      earningRate: crownPerMarksmanPoint
    }));
    hunterStakeByToken[tokenId] = TimeStake({
      owner: account,
      tokenId: tokenId,
      time: uint48(block.timestamp)
    });
    // Phase 2 - Mark earning point as valid
    hasRecentEarningPoint[tokenId] = true;
    totalHuntersStaked += 1;
    emit TokenStaked("HUNTER", tokenId, account);
  }

  // NB: Param struct is a workaround for too many variables error
  struct Param {
    IFoxGameNFT nftContract;
    uint16 tokenId;
    bool unstake;
    uint256 seed;
  }

  /**
   * Realize $CARROT earnings and optionally unstake tokens.
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   * @param blocknums list of blocks each token previously was staked or claimed.
   * @param seeds random (off-chain) seeds provided for one-time use.
   * @param sig signature verification.
   */
  function claimRewardsAndUnstake(bool unstake, uint16[] calldata tokenIds, uint32[] calldata blocknums, uint256[] calldata seeds,  bytes calldata sig) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos");
    require(isValidClaimSignature(msg.sender, tokenIds, unstake, blocknums, seeds, sig), "invalid signature");
    require(tokenIds.length == blocknums.length && blocknums.length == seeds.length, "seed mismatch");

    // Risk factors
    bool elevatedRisk =
      (corruptionStartDate != 0 && corruptionStartDate < block.timestamp) && // corrupted
      (barrelPurchaseDate[msg.sender] == 0);                                 // does not have barrel

    // Calculate rewards for each token
    uint128 reward;
    mapping(uint16 => uint32) storage senderBlocks = _stakeClaimBlock[msg.sender][unstake ? UNSTAKE_AND_CLAIM_IDX : CLAIM_IDX];
    Param memory params;
    for (uint8 i; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];

      // Confirm previous block matches seed generation
      require(senderBlocks[tokenId] == blocknums[i], "seed not match");

      // Set new entropy for next claim (dont bother if unstaking)
      if (!unstake) {
        senderBlocks[tokenId] = uint32(block.number);
      }

      // NB: Param struct is a workaround for too many variables
      params.nftContract = getTokenContract(tokenId);
      params.tokenId = tokenId;
      params.unstake = unstake;
      params.seed = seeds[i];

      IFoxGameNFT.Kind kind = _getKind(params.nftContract, params.tokenId);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        reward += _claimRabbitsFromKeep(params.nftContract, params.tokenId, params.unstake, params.seed, elevatedRisk);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        reward += _claimFoxFromDen(params.nftContract, params.tokenId, params.unstake, params.seed, elevatedRisk);
      } else { // HUNTER
        reward += _claimHunterFromCabin(params.nftContract, params.tokenId, params.unstake);
      }
    }

    // Disburse rewards
    if (reward != 0) {
      foxCrown.mint(msg.sender, reward);
    }
  }

  /**
   * realize $CARROT earnings for a single Rabbit and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked foxes
   * if unstaking, there is a 50% chance all $CARROT is stolen
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Rabbit to claim earnings from
   * @param unstake whether or not to unstake the Rabbit
   * @param seed account seed
   * @param elevatedRisk true if the user is facing higher risk of losing their token
   * @return reward - the amount of $CARROT earned
   */
  function _claimRabbitsFromKeep(IFoxGameNFT nftContract, uint16 tokenId, bool unstake, uint256 seed, bool elevatedRisk) internal returns (uint128 reward) {
    TimeStake storage stake = rabbitStakeByToken[tokenId];
    require(stake.owner == msg.sender, "not owner");
    uint48 time = uint48(block.timestamp);
    uint48 stakeStart = stake.time < divergenceTime ? divergenceTime : stake.time; // phase 2 reset
    require(!(unstake && time - stakeStart < RABBIT_MINIMUM_TO_EXIT), "needs 2 days of crown");

    // $CROWN time-based rewards
    if (totalCrownEarned < MAXIMUM_GLOBAL_CROWN) {
      reward = (time - stakeStart) * RABBIT_EARNING_RATE;
    } else if (stakeStart <= lastCrownClaimTimestamp) {
      // stop earning additional $CROWN if it's all been earned
      reward = (lastCrownClaimTimestamp - stakeStart) * RABBIT_EARNING_RATE;
    }

    // Update reward based on game rules
    uint128 tax;
    if (unstake) {
      // Chance of all $CROWN stolen (normal=50% vs corrupted=60%)
      if (((seed >> 245) % 10) < (elevatedRisk ? 6 : 5)) {
        _payTaxToPredators(reward, true);
        tax = reward;
        reward = 0;
      }
      delete rabbitStakeByToken[tokenId];
      totalRabbitsStaked -= 1;
      // send back Rabbit
      nftContract.safeTransferFrom(address(this), msg.sender, tokenId, "");
    } else {
      // Pay foxes their tax
      tax = reward * RABBIT_CLAIM_TAX_PERCENTAGE / 100;
      _payTaxToPredators(tax, false);
      reward = reward * (100 - RABBIT_CLAIM_TAX_PERCENTAGE) / 100;
      // Update last earned time
      rabbitStakeByToken[tokenId] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time
      });
    }

    emit CrownClaimed("RABBIT", tokenId, stake.owner, unstake, reward, tax, elevatedRisk);
  }

  /**
   * realize $CARROT earnings for a single Fox and optionally unstake it
   * foxes earn $CARROT proportional to their Alpha rank
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param unstake whether or not to unstake the Fox
   * @param seed account seed
   * @param elevatedRisk true if the user is facing higher risk of losing their token
   * @return reward - the amount of $CARROT earned
   */
  function _claimFoxFromDen(IFoxGameNFT nftContract, uint16 tokenId, bool unstake, uint256 seed, bool elevatedRisk) internal returns (uint128 reward) {
    require(nftContract.ownerOf(tokenId) == address(this), "not staked");
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    EarningStake storage stake = foxStakeByCunning[cunning][foxHierarchy[tokenId]];
    require(stake.owner == msg.sender, "not owner");

    // Calculate advantage-based rewards
    uint128 migratedEarningPoint = hasRecentEarningPoint[tokenId] ? stake.earningRate : 0; // phase 2 reset
    if (crownPerCunningPoint > migratedEarningPoint) {
      reward = (cunning) * (crownPerCunningPoint - migratedEarningPoint);
    }
    if (unstake) {
      totalCunningPointsStaked -= cunning; // Remove Alpha from total staked
      EarningStake storage lastStake = foxStakeByCunning[cunning][foxStakeByCunning[cunning].length - 1];
      foxStakeByCunning[cunning][foxHierarchy[tokenId]] = lastStake; // Shuffle last Fox to current position
      foxHierarchy[lastStake.tokenId] = foxHierarchy[tokenId];
      foxStakeByCunning[cunning].pop(); // Remove duplicate
      delete foxHierarchy[tokenId]; // Delete old mapping
      totalFoxesStaked -= 1;

      // Determine if Fox should be stolen by hunter (normal=5% vs corrupted=20%)
      address recipient = msg.sender;
      if (((seed >> 245) % (elevatedRisk ? 5 : hunterStealFoxProbabilityMod)) == 0) {
        recipient = _randomHunterOwner(seed);
        if (recipient == address(0x0)) {
          recipient = msg.sender;
        } else if (recipient != msg.sender) {
          emit FoxStolen(tokenId, recipient, msg.sender);
        }
      }
      nftContract.safeTransferFrom(address(this), recipient, tokenId, "");
    } else {
      // Update earning point
      foxStakeByCunning[cunning][foxHierarchy[tokenId]] = EarningStake({
        owner: msg.sender,
        tokenId: tokenId,
        earningRate: crownPerCunningPoint
      });
      hasRecentEarningPoint[tokenId] = true;
    }

    emit CrownClaimed("FOX", tokenId, stake.owner, unstake, reward, 0, elevatedRisk);
  }

  /**
   * realize $CARROT earnings for a single Fox and optionally unstake it
   * foxes earn $CARROT proportional to their Alpha rank
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param unstake whether or not to unstake the Fox
   * @return reward - the amount of $CARROT earned
   */
  function _claimHunterFromCabin(IFoxGameNFT nftContract, uint16 tokenId, bool unstake) internal returns (uint128 reward) {
    require(foxNFTGen1.ownerOf(tokenId) == address(this), "not staked");
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    EarningStake storage earningStake = hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]];
    require(earningStake.owner == msg.sender, "not owner");
    uint48 time = uint48(block.timestamp);

    // Calculate advantage-based rewards
    uint128 migratedEarningPoint = hasRecentEarningPoint[tokenId] ? earningStake.earningRate : 0; // phase 2 reset
    if (crownPerCunningPoint > migratedEarningPoint) {
      reward = (marksman) * (crownPerMarksmanPoint - migratedEarningPoint);
    }
    if (unstake) {
      totalMarksmanPointsStaked -= marksman; // Remove Alpha from total staked
      EarningStake storage lastStake = hunterStakeByMarksman[marksman][hunterStakeByMarksman[marksman].length - 1];
      hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]] = lastStake; // Shuffle last Fox to current position
      hunterHierarchy[lastStake.tokenId] = hunterHierarchy[tokenId];
      hunterStakeByMarksman[marksman].pop(); // Remove duplicate
      delete hunterHierarchy[tokenId]; // Delete old mapping
    } else {
      // Update earning point
      hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]] = EarningStake({
        owner: msg.sender,
        tokenId: tokenId,
        earningRate: crownPerMarksmanPoint
      });
      hasRecentEarningPoint[tokenId] = true;
    }

    // Calcuate time-based rewards
    TimeStake storage timeStake = hunterStakeByToken[tokenId];
    require(timeStake.owner == msg.sender, "not owner");
    uint48 stakeStart = timeStake.time < divergenceTime ? divergenceTime : timeStake.time; // phase 2 reset
    if (totalCrownEarned < MAXIMUM_GLOBAL_CROWN) {
      reward += (time - stakeStart) * HUNTER_EARNING_RATE;
    } else if (stakeStart <= lastCrownClaimTimestamp) {
      // stop earning additional $CARROT if it's all been earned
      reward += (lastCrownClaimTimestamp - stakeStart) * HUNTER_EARNING_RATE;
    }
    if (unstake) {
      delete hunterStakeByToken[tokenId];
      totalHuntersStaked -= 1;
      // Unstake to owner
      foxNFTGen1.safeTransferFrom(address(this), msg.sender, tokenId, "");
    } else {
      // Update last earned time
      hunterStakeByToken[tokenId] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time
      });
    }

    emit CrownClaimed("HUNTER", tokenId, earningStake.owner, unstake, reward, 0, false);
  }

  // Struct to abstract away calculation of rewards from claiming rewards
  struct TokenReward {
    address owner;
    IFoxGameNFT.Kind kind;
    uint128 reward;
    uint128 corruptedCarrot;
  }

  /**
   * Realize $CARROT earnings. There's no risk nor tax involed other than corruption. 
   * @param tokenId the token ID
   * @param time current time
   * @return claim reward information 
   */
  function getCarrotReward(uint16 tokenId, uint48 time) private view returns (TokenReward memory claim) {
    IFoxGameNFT nftContract = getTokenContract(tokenId);
    claim.kind = _getKind(nftContract, tokenId);
    if (claim.kind == IFoxGameNFT.Kind.RABBIT) {
      claim = _getCarrotForRabbit(tokenId, time);
    } else if (claim.kind == IFoxGameNFT.Kind.FOX) {
      claim = _getCarrotForFox(nftContract, tokenId, time);
    } else { // HUNTER
      claim = _getCarrotForHunter(nftContract, tokenId, time);
    }
  }

  /**
   * Calculate carrot rewards for the given tokens.
   * @param tokenIds list of tokens
   * @return claims list of reward objects
   */
  function getCarrotRewards(uint16[] calldata tokenIds) external view returns (TokenReward[] memory claims) {
    uint48 time = uint48(block.timestamp);
    claims = new TokenReward[](tokenIds.length);
    for (uint8 i; i < tokenIds.length; i++) {
      if (!tokenCarrotClaimed[tokenIds[i]]) {
        claims[i] = getCarrotReward(tokenIds[i], time);
      }
    }
  }

  /**
   * Realize $CARROT earnings. There's no risk nor tax involed other than corruption. 
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function claimCarrotRewards(uint16[] calldata tokenIds) external  {
    require(tx.origin == msg.sender, "eos");

    uint128 reward;
    TokenReward memory claim;
    uint48 time = uint48(block.timestamp);
    for (uint8 i; i < tokenIds.length; i++) {
      if (!tokenCarrotClaimed[tokenIds[i]]) {
        claim = getCarrotReward(tokenIds[i], time);
        require(claim.owner == msg.sender, "not owner");
        reward += claim.reward;
        emit ClaimCarrot(claim.kind, tokenIds[i], claim.owner, claim.reward, claim.corruptedCarrot);
        tokenCarrotClaimed[tokenIds[i]] = true;
      }
    }

    // Disburse rewards
    if (reward != 0) {
      foxCarrot.mint(msg.sender, reward);
    }
  }

  /**
   * Calculate the carrot accumulated per token.
   * @param time current time
   */
  function calculateCorruptedCarrot(address account, uint128 reward, uint48 time) private view returns (uint128 corruptedCarrot) {
    // If user has rewards and corruption has started
    if (reward > 0 && corruptionStartDate != 0 && time > corruptionStartDate) {
      // Calulate time that corruption was in effect
      uint48 barrelTime = barrelPurchaseDate[account];
      uint128 unsafeElapsed = (barrelTime == 0 ? time - corruptionStartDate     // never bought barrel
          : barrelTime > corruptionStartDate ? barrelTime - corruptionStartDate // bought after corruption
          : 0                                                                   // bought before corruption
      );
      // Subtract from reward
      if (unsafeElapsed > 0) {
        corruptedCarrot = (reward * unsafeElapsed * CORRUPTION_BURN_PERCENT_RATE) / 1000000000000000000 /* 1eth */;
      }
    }
  }

  /**
   * Realize $CARROT earnings for a single Rabbit
   * @param tokenId the ID of the Rabbit to claim earnings from
   * @param time current time
   * @return claim carrot claim object
   */
  function _getCarrotForRabbit(uint16 tokenId, uint48 time) private view returns (TokenReward memory claim) {
    // Carrot time-based rewards
    uint128 reward;
    TimeStake storage stake = rabbitStakeByToken[tokenId];
    if (divergenceTime == 0 || time < divergenceTime) { // divergence has't yet started
      reward = (time - stake.time) * RABBIT_EARNING_RATE;
    } else if (stake.time < divergenceTime) { // last moment to accrue carrot
      reward = (divergenceTime - stake.time) * RABBIT_EARNING_RATE;
    }

    claim.corruptedCarrot = calculateCorruptedCarrot(msg.sender, reward, time);
    claim.reward = reward - claim.corruptedCarrot;
    claim.owner = stake.owner;
  }

  /**
   * Realize $CARROT earnings for a single Fox
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param time current time
   * @return claim carrot claim object
   */
  function _getCarrotForFox(IFoxGameNFT nftContract, uint16 tokenId, uint48 time) private view returns (TokenReward memory claim) {
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    EarningStake storage stake = foxStakeByCunning[cunning][foxHierarchy[tokenId]];

    // Calculate advantage-based rewards
    uint128 reward;
    if (carrotPerCunningPoint > stake.earningRate) {
      reward = cunning * (carrotPerCunningPoint - stake.earningRate);
    }

    // Remove corrupted carrot
    claim.corruptedCarrot = calculateCorruptedCarrot(msg.sender, reward, time);
    claim.reward = reward - claim.corruptedCarrot;
    claim.owner = stake.owner;
  }

  /**
   * Realize $CARROT earnings for a single hunter
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param time current time
   * @return claim carrot claim object
   */
  function _getCarrotForHunter(IFoxGameNFT nftContract, uint16 tokenId, uint48 time) private view returns (TokenReward memory claim) {
    require(foxNFTGen1.ownerOf(tokenId) == address(this), "not staked");
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    EarningStake storage earningStake = hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]];
    require(earningStake.owner == msg.sender, "not owner");
 
    // Calculate advantage-based rewards
    uint128 reward;
    if (carrotPerMarksmanPoint > earningStake.earningRate) {
      reward = marksman * (carrotPerMarksmanPoint - earningStake.earningRate);
    }

    // Carrot time-based rewards
    TimeStake storage timeStake = hunterStakeByToken[tokenId];
    if (divergenceTime == 0 || time < divergenceTime) {
      reward += (time - timeStake.time) * HUNTER_EARNING_RATE;
    } else if (timeStake.time < divergenceTime) {
      reward += (divergenceTime - timeStake.time) * HUNTER_EARNING_RATE;
    }

    // Remove corrupted carrot
    claim.corruptedCarrot = calculateCorruptedCarrot(msg.sender, reward, time);
    claim.reward = reward - claim.corruptedCarrot;
    claim.owner = earningStake.owner;
  }

  /** 
   * Add $CARROT claimable pots for hunters and foxes
   * @param amount $CARROT to add to the pot
   * @param includeHunters true if hunters take a cut of the spoils
   */
  function _payTaxToPredators(uint128 amount, bool includeHunters) internal {
    uint128 amountDueFoxes = amount;

    // Hunters take their cut first
    if (includeHunters) {
      uint128 amountDueHunters = amount * hunterTaxCutPercentage / 100;
      amountDueFoxes -= amountDueHunters;

      // Update hunter pools
      if (totalMarksmanPointsStaked == 0) {
        unaccountedHunterRewards += amountDueHunters;
      } else {
        crownPerMarksmanPoint += (amountDueHunters + unaccountedHunterRewards) / totalMarksmanPointsStaked;
        unaccountedHunterRewards = 0;
      }
    }

    // Update fox pools
    if (totalCunningPointsStaked == 0) {
      unaccountedFoxRewards += amountDueFoxes;
    } else {
      // makes sure to include any unaccounted $CARROT 
      crownPerCunningPoint += (amountDueFoxes + unaccountedFoxRewards) / totalCunningPointsStaked;
      unaccountedFoxRewards = 0;
    }
  }

  /**
   * Tracks $CARROT earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    uint48 time = uint48(block.timestamp);
    // CROWN - Capped by supply
    if (totalCrownEarned < MAXIMUM_GLOBAL_CROWN) {
      uint48 elapsed = time - lastCrownClaimTimestamp;
      totalCrownEarned +=
        (elapsed * totalRabbitsStaked * RABBIT_EARNING_RATE) +
        (elapsed * totalHuntersStaked * HUNTER_EARNING_RATE);
      lastCrownClaimTimestamp = time;
    }
    _;
  }

  /**
   * Get token kind (rabbit, fox, hunter)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (IFoxGameNFT.Kind) {
    return nftContract.getTraits(tokenId).kind;
  }

  /**
   * gets the alpha score for a Fox
   * @param tokenId the ID of the Fox to get the alpha score for
   * @return the alpha score of the Fox (5-8)
   */
  function _getAdvantagePoints(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (uint8) {
    return MAX_ADVANTAGE - nftContract.getTraits(tokenId).advantage; // alpha index is 0-3
  }

  /**
   * chooses a random Fox thief when a newly minted token is stolen
   * @param seed a random value to choose a Fox from
   * @return the owner of the randomly selected Fox thief
   */
  function randomFoxOwner(uint256 seed) external view returns (address) {
    if (totalCunningPointsStaked == 0) {
      return address(0x0); // use 0x0 to return to msg.sender
    }
    // choose a value from 0 to total alpha staked
    uint256 bucket = (seed & 0xFFFFFFFF) % totalCunningPointsStaked;
    uint256 cumulative;
    seed >>= 32;
    // loop through each cunning bucket of Foxes
    for (uint8 i = MAX_ADVANTAGE - 3; i <= MAX_ADVANTAGE; i++) {
      cumulative += foxStakeByCunning[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Fox with that alpha score
      return foxStakeByCunning[i][seed % foxStakeByCunning[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * Chooses a random Hunter to steal a fox.
   * @param seed a random value to choose a Hunter from
   * @return the owner of the randomly selected Hunter thief
   */
  function _randomHunterOwner(uint256 seed) internal view returns (address) {
    if (totalMarksmanPointsStaked == 0) {
      return address(0x0); // use 0x0 to return to msg.sender
    }
    // choose a value from 0 to total alpha staked
    uint256 bucket = (seed & 0xFFFFFFFF) % totalMarksmanPointsStaked;
    uint256 cumulative;
    seed >>= 32;
    // loop through each cunning bucket of Foxes
    for (uint8 i = MAX_ADVANTAGE - 3; i <= MAX_ADVANTAGE; i++) {
      cumulative += hunterStakeByMarksman[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Fox with that alpha score
      return hunterStakeByMarksman[i][seed % hunterStakeByMarksman[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * Realize $CROWN earnings
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function calculateRewards(uint16[] calldata tokenIds) external view returns (TokenReward[] memory tokenRewards) {
    require(tx.origin == msg.sender, "eos only");

    IFoxGameNFT.Kind kind;
    IFoxGameNFT nftContract;
    tokenRewards = new TokenReward[](tokenIds.length);
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      nftContract = getTokenContract(tokenIds[i]);
      kind = _getKind(nftContract, tokenIds[i]);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        tokenRewards[i] = _calculateRabbitReward(tokenIds[i], time);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        tokenRewards[i] = _calculateFoxReward(nftContract, tokenIds[i]);
      } else { // HUNTER
        tokenRewards[i] = _calculateHunterReward(nftContract, tokenIds[i], time);
      }
    }
  }

  /**
   * Calculate rabbit reward.
   * @param tokenId the ID of the Rabbit to claim earnings from
   * @param time currnet block time
   * @return tokenReward token reward response
   */
  function _calculateRabbitReward(uint16 tokenId, uint48 time) internal view returns (TokenReward memory tokenReward) {
    TimeStake storage stake = rabbitStakeByToken[tokenId];
    uint48 stakeStart = stake.time < divergenceTime ? divergenceTime : stake.time; // phase 2 reset

    // Calcuate time-based rewards
    uint128 reward;
    if (totalCrownEarned < MAXIMUM_GLOBAL_CROWN) {
      reward = (time - stakeStart) * RABBIT_EARNING_RATE;
    } else if (stakeStart <= lastCrownClaimTimestamp) {
      // stop earning additional $CROWN if it's all been earned
      reward = (lastCrownClaimTimestamp - stakeStart) * RABBIT_EARNING_RATE;
    }

    // Compose reward object
    tokenReward.owner = stake.owner;
    tokenReward.reward = reward * (100 - RABBIT_CLAIM_TAX_PERCENTAGE) / 100;
  }

  /**
   * Calculate fox reward.
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @return tokenReward token reward response
   */
  function _calculateFoxReward(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (TokenReward memory tokenReward) {
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    EarningStake storage stake = foxStakeByCunning[cunning][foxHierarchy[tokenId]];

    // Calculate advantage-based rewards
    uint128 reward;
    uint128 migratedEarningPoint = hasRecentEarningPoint[tokenId] ? stake.earningRate : 0; // phase 2 reset
    if (crownPerCunningPoint > migratedEarningPoint) {
      reward = (cunning) * (crownPerCunningPoint - migratedEarningPoint);
    }

    // Compose reward object
    tokenReward.owner = stake.owner;
    tokenReward.reward = reward;
  }

  /**
   * Calculate hunter reward.
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param time currnet block time
   * @return tokenReward token reward response
   */
  function _calculateHunterReward(IFoxGameNFT nftContract, uint16 tokenId, uint48 time) internal view returns (TokenReward memory tokenReward) {
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    EarningStake storage earningStake = hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]];

    // Calculate advantage-based rewards
    uint128 reward;
    uint128 migratedEarningPoint = hasRecentEarningPoint[tokenId] ? earningStake.earningRate : 0; // phase 2 reset
    if (crownPerMarksmanPoint > migratedEarningPoint) {
      reward = (marksman) * (crownPerMarksmanPoint - migratedEarningPoint);
    }

    // Calcuate time-based rewards
    TimeStake storage timeStake = hunterStakeByToken[tokenId];
    uint48 stakeStart = timeStake.time < divergenceTime ? divergenceTime : timeStake.time; // phase 2 reset
    require(timeStake.owner == msg.sender, "not owner");
    if (totalCrownEarned < MAXIMUM_GLOBAL_CROWN) {
      reward += (time - stakeStart) * HUNTER_EARNING_RATE;
    } else if (stakeStart <= lastCrownClaimTimestamp) {
      reward += (lastCrownClaimTimestamp - stakeStart) * HUNTER_EARNING_RATE;
    }

    // Compose reward object
    tokenReward.owner = earningStake.owner;
    tokenReward.reward = reward;
  }

  /**
   * Toggle staking / unstaking.
   */
  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /**
   * Sets a new signature verifier.
   */
  function setExternalAddresses(address[5] memory addresses) external onlyOwner {
    signVerifier = addresses[0];
    foxNFT = IFoxGameNFT(addresses[1]);
    foxNFTGen1 = IFoxGameNFT(addresses[2]);
    foxCarrot = IFoxGameCarrot(addresses[3]);
    foxCrown = IFoxGameCrown(addresses[4]);
  }

  /**
   * Interface support to allow player staking.
   */
  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {    
    require(from == address(0x0));
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }
}