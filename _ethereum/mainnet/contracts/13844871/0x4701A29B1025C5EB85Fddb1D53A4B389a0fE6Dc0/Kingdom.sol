// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IHNDGame.sol";
import "./IHND.sol";
import "./IEXP.sol";
import "./IKingdom.sol";

contract Kingdom is IKingdom, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  
  // maximum rank for a Hero/Demon
  uint8 public constant MAX_RANK = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  uint256 private totalRankStaked;
  uint256 private numHeroesStaked;

  event TokenStaked(address indexed owner, uint256 indexed tokenId, bool indexed isHero, uint256 value);
  event HeroClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
  event DemonClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

  // reference to the HND NFT contract
  IHND public HNDNFT;
  // reference to the HND NFT contract
  IHNDGame public HNDGame;
  // reference to the $EXP contract for minting $EXP earnings
  IEXP public expToken;

  // maps tokenId to stake
  mapping(uint256 => Stake) private kingdom; 
  // maps rank to all Demon staked with that rank
  mapping(uint256 => Stake[]) private army; 
  // tracks location of each Demon in Army
  mapping(uint256 => uint256) private armyIndices; 
  // any rewards distributed when no demons are stakd
  mapping(address => uint256[]) public stakedTokenOwners;
  //holds mapping of their position in stakedTokenOwners
  mapping(uint256 => uint256) private stakedTokenIndex;

  uint256 private unaccountedRewards = 0; 
  // amount of $EXP due for each rank point staked
  uint256 private expPerRank = 0; 

  // heroes earn 10000 $EXP per day
  uint256 public constant DAILY_EXP_RATE = 10000 ether;

  // gen0 heroes earn 10000 $EXP per day
  uint256 public constant GEN0_DAILY_EXP_RATE = 15000 ether;

  // heroes must have 2 days worth of $EXP to unstake or else they're still guarding the Kingdom
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // demons take a 20% tax on all $EXP claimede
  uint256 public constant EXP_CLAIM_TAX_PERCENTAGE = 20;

  // when heroes are leaving demons have 50% chance to take 50% of their earned $EXP instead of 20%
  uint256 public constant EXP_STOLEN_DENOMINATOR = 2;

  // 10,000,000,000  $EXP used and cycled through during combat
  uint256 public constant MAXIMUM_GLOBAL_EXP = 10000000000 ether;
  
  // $EXP that has been dispensed from the faucet during combat
  uint256 public expFromFaucet;
  // the last time $EXP was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $EXP
  bool public rescueEnabled = false;

  mapping(address => bool) private admins;

  /**
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(HNDNFT) != address(0) && address(expToken) != address(0) 
        && address(HNDGame) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _HNDNFT, address _exp, address _HNDGame) external onlyOwner {
    HNDNFT = IHND(_HNDNFT);
    expToken = IEXP(_exp);
    HNDGame = IHNDGame(_HNDGame);
  }

  /** STAKING */

  /**
   * adds Heros and Demons to the Kingdom and Army
   * @param account the address of the staker
   * @param tokenIds the IDs of the Heros and Demons to stake
   */
  function addManyToKingdom(address account, uint16[] calldata tokenIds) external override nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(HNDGame), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(HNDGame)) { // dont do this step if its a mint + stake
        require(HNDNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        HNDNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (HNDNFT.isHero(tokenIds[i])) 
        _addHeroToKingdom(account, tokenIds[i]);
      else 
        _addDemonToArmy(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Hero to the Kingdom
   * @param account the address of the staker
   * @param tokenId the ID of the Hero to add to the Kingdom
   */
  function _addHeroToKingdom(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    kingdom[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    stakedTokenIndex[tokenId] = stakedTokenOwners[account].length;
    stakedTokenOwners[account].push(tokenId);
    numHeroesStaked += 1;
    emit TokenStaked(account, tokenId, true, block.timestamp);
  }

  /**
   * adds a single Demon to the Army
   * @param account the address of the staker
   * @param tokenId the ID of the Demon to add to the Army
   */
  function _addDemonToArmy(address account, uint256 tokenId) internal {
    uint8 rank = _rankForDemon(tokenId);
    totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
    armyIndices[tokenId] = army[rank].length; // Store the location of the demon in the Army
    army[rank].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(expPerRank)
    })); // Add the demon to the Army
    stakedTokenIndex[tokenId] = stakedTokenOwners[account].length;
    stakedTokenOwners[account].push(tokenId);
    emit TokenStaked(account, tokenId, false, expPerRank);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $EXP earnings and optionally unstake tokens from the Kingdom
   * to unstake a Hero it will require it has 2 days worth of $EXP unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromKingdom(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(HNDGame), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (HNDNFT.isHero(tokenIds[i])) {
        owed += _claimHeroFromKingdom(tokenIds[i], unstake);
      }
      else {
        owed += _claimDemonFromArmy(tokenIds[i], unstake);
      }
    }
    expToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }

    expToken.mint(_msgSender(), owed);
  }

  function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = HNDNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    Stake memory stake = kingdom[tokenId];
    if(HNDNFT.isHero(tokenId)) {
      if (expFromFaucet < MAXIMUM_GLOBAL_EXP) {
        owed = (block.timestamp - stake.value) * DAILY_EXP_RATE / 1 days;
        if (HNDNFT.getPaidTokens() >= tokenId) { // if they are a gen0 hero earn 15k
          owed = (block.timestamp - stake.value) * GEN0_DAILY_EXP_RATE / 1 days;
        }
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $EXP production stopped already
      } else {
        owed = (lastClaimTimestamp - stake.value) * DAILY_EXP_RATE / 1 days; // stop earning additional $EXP if it's all been earned

        if (HNDNFT.getPaidTokens() >= tokenId) {
          (lastClaimTimestamp - stake.value) * GEN0_DAILY_EXP_RATE / 1 days;
        }
      }
    }
    else {
      uint8 rank = _rankForDemon(tokenId);
      owed = (rank) * (expPerRank - stake.value); // Calculate portion of tokens based on Rank
    }
  }

  /**
   * realize $EXP earnings for a single Hero and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Demons
   * if unstaking, there is a 50% chance all $EXP is stolen
   * @param tokenId the ID of the Heros to claim earnings from
   * @param unstake whether or not to unstake the Heros
   * @return owed - the amount of $EXP earned
   */
  function _claimHeroFromKingdom(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(HNDNFT.ownerOf(tokenId) == address(this), "Kingdom: Claiming unstaked hero!");
    Stake memory stake = kingdom[tokenId];
    require(stake.owner == _msgSender(), "Kingdom: Claiming unowned hero!");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "Kingdom: Hero is still guarding!");
    if (expFromFaucet < MAXIMUM_GLOBAL_EXP) {
      owed = (block.timestamp - stake.value) * DAILY_EXP_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $EXP production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_EXP_RATE / 1 days; // stop earning additional $EXP if it's all been earned
    }
    if (unstake) {
      // 50% chance of half $EXP being stolen
      if (uint256(keccak256(abi.encode(blockhash(block.number-1), _msgSender(), tokenId))) % 2 == 1) { 

        //steal half of $EXP accumulated
        _payDemonTax(owed/EXP_STOLEN_DENOMINATOR); 

        // keep half the $EXP
        owed = (owed/EXP_STOLEN_DENOMINATOR);
      }
      delete kingdom[tokenId];
      delete stakedTokenOwners[_msgSender()][stakedTokenIndex[tokenId]];
      stakedTokenIndex[tokenId] = 0;
      numHeroesStaked -= 1;
      
      HNDNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Hero
    } else {
      _payDemonTax(owed * EXP_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked demons
      
      // send leftover
      owed = owed * (100 - EXP_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Hero owner
      
      // reset their stake
      kingdom[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); 
    }
    emit HeroClaimed(tokenId, unstake, owed);
  }

  /**
   * realize $EXP earnings for a single Demon and optionally unstake it
   * Demons earn $EXP proportional to their rank
   * @param tokenId the ID of the Demon to claim earnings from
   * @param unstake whether or not to unstake the Demon
   * @return  owed  the amount of $EXP earned
   */
  function _claimDemonFromArmy(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(HNDNFT.ownerOf(tokenId) == address(this), "Kingdom: Claiming unstaked demon!");
    uint8 rank = _rankForDemon(tokenId);
    Stake memory stake = army[rank][armyIndices[tokenId]];
    require(stake.owner == _msgSender(), "Kingdom: Claiming unowned demon!");
    owed = (rank) * (expPerRank - stake.value); // Calculate portion of tokens based on Rank
    if (unstake) {
      totalRankStaked -= rank; // Remove rank from total staked
      Stake memory lastStake = army[rank][army[rank].length - 1];
      army[rank][armyIndices[tokenId]] = lastStake; // Shuffle last Demon to current position
      armyIndices[lastStake.tokenId] = armyIndices[tokenId];
      army[rank].pop(); // Remove duplicate
      delete armyIndices[tokenId]; // Delete old mapping
      delete stakedTokenOwners[_msgSender()][stakedTokenIndex[tokenId]];
      stakedTokenIndex[tokenId] = 0;
      // Always remove last to guard against reentrance
      HNDNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Demon
    } else {

      // we reset their stake
      army[rank][armyIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(expPerRank)
      });
    }
    emit DemonClaimed(tokenId, unstake, owed);
  }
  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint8 rank;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (HNDNFT.isHero(tokenId)) {
        stake = kingdom[tokenId];
        require(stake.owner == _msgSender(), "must own token");
        delete kingdom[tokenId];
        numHeroesStaked -= 1;
        HNDNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Heros
        emit HeroClaimed(tokenId, true, 0);
      } else {
        rank = _rankForDemon(tokenId);
        stake = army[rank][armyIndices[tokenId]];
        require(stake.owner == _msgSender(), "must own token");
        totalRankStaked -= rank; // Remove Rank from total staked
        lastStake = army[rank][army[rank].length - 1];
        army[rank][armyIndices[tokenId]] = lastStake; // Shuffle last Demon to current position
        armyIndices[lastStake.tokenId] = armyIndices[tokenId];
        army[rank].pop(); // Remove duplicate
        delete armyIndices[tokenId]; // Delete old mapping
        HNDNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Demon
        emit DemonClaimed(tokenId, true, 0);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $EXP to claimable pot for the Army
   * @param amount $EXP to add to the pot
   */
  function _payDemonTax(uint256 amount) internal {
    if (totalRankStaked == 0) { // if there's no staked demons
      unaccountedRewards += amount; // keep track of $EXP due to demons
      return;
    }
    // makes sure to include any unaccounted $EXP 
    expPerRank += (amount + unaccountedRewards) / totalRankStaked;
    unaccountedRewards = 0;
  }

    /** 
   * add $EXP to claimable pot for the Army
   * @param amount $EXP to add to the pot
   */
  function recycleExp(uint256 amount) override external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    expFromFaucet -= amount;
  }

  /**
   * tracks $EXP earnings to ensure it stops once 10 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (expFromFaucet < MAXIMUM_GLOBAL_EXP) {
      expFromFaucet += 
        (block.timestamp - lastClaimTimestamp)
        * numHeroesStaked
        * DAILY_EXP_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /** ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * gets the rank score for a Demon
   * @param tokenId the ID of the Demon to get the rank score for
   * @return the rank score of the Demon (5-8)
   */
  function _rankForDemon(uint256 tokenId) internal view returns (uint8) {
    IHND.HeroDemon memory s = HNDNFT.getTokenTraits(tokenId);
    return MAX_RANK - s.rankIndex; // rank index is 0-3
  }

  /**
   * chooses a random Demon thief when a newly minted token is stolen
   * @param seed a random value to choose a Demon from
   * @return the owner of the randomly selected Demon thief
   */
  function randomDemonOwner(uint256 seed) external view override returns (address) {
    if (totalRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Demons with the same rank score
    for (uint i = MAX_RANK - 3; i <= MAX_RANK; i++) {
      cumulative += army[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Demon with that rank score
      return army[i][seed % army[i].length].owner;
    }
    return address(0x0);
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to Kingdom directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  /**
  * enables an address to mint / burn
  * @param addr the address to enable
  */
  function addAdmin(address addr) external onlyOwner {
      admins[addr] = true;
  }

  /**
  * disables an address from minting / burning
  * @param addr the address to disbale
  */
  function removeAdmin(address addr) external onlyOwner {
      admins[addr] = false;
  }
  
  }

