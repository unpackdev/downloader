// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./IVillage.sol";
import "./IRandomizer.sol";
import "./IGOLD.sol";
import "./ITraits.sol";
import "./VAndV.sol";

contract Village is IVillage, Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
  using Address for address;

  // Events
  event GoldTaxed(address from, uint256 taxed);
  event GoldStolen(address from, uint256 total);

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  // maximum alpha score for a viking
  uint8 public constant MAX_ALPHA = 8;
  // villagers earn 10000 $GOLD per day
  uint256 public constant DAILY_GOLD_RATE = 10000 ether;
  // villagers must have 2 days worth of $GOLD to unstake
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // vikings take a 20% tax on all $GOLD earned
  uint256 public constant GOLD_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 4 billion $GOLD earned through staking
  uint256 public constant MAXIMUM_GLOBAL_GOLD = 4000000000 ether;

  // total alpha scores staked
  uint256 public totalAlphaStaked = 0;
  // any rewards distributed when no vikings are staked
  uint256 public unaccountedRewards = 0;
  // amount of $GOLD due for each alpha point staked
  uint256 public rewardsPerAlpha = 0;
  // amount of $GOLD earned so far
  uint256 public totalGoldEarned = 0;
  // number of villagers staked
  uint256 public totalVillagersStaked = 0;
  // number of vikings staked
  uint256 public totalVikingsStaked = 0;
  // the last time $GOLD was claimed
  uint256 public lastClaimTimestamp = 0;

  // maps tokenId to stake
  mapping(uint256 => Stake) private village;
  // maps alpha to all viking raid parties with that alpha
  mapping(uint8 => Stake[]) private parties;
  // tracks location of each viking in raid parties
  mapping(uint256 => uint256) private partyIndices;
  // tracks token IDs owned by which addresses
  mapping(address => uint256[]) private ownerTokens;
  // tracks location of each token in owner tokens
  mapping(uint256 => uint256) private ownerTokensIndices;

  // reference to randomizer
  IRandomizer private randomizer;
  // reference to $GOLD
  IGOLD private gold;
  // reference to traits
  ITraits private traits;
  // reference to vandv
  VAndV private vandv;

  /**
   * create the contract
   */
  constructor() {
    _pause();
  }

  /**
   * add your villagers and vikings to the contract
   * @param tokenIds the IDs of the tokens to stake
   */
  function stakeTokens(uint16[] calldata tokenIds) external nonReentrant whenNotPaused {
    require(tx.origin == _msgSender() && !_msgSender().isContract(), "VILLAGE: Only EOA");

    for (uint i = 0; i < tokenIds.length; i++) {
      require(vandv.ownerOf(tokenIds[i]) == _msgSender(), "VILLAGE: Doesn't own that token");

      vandv.transferFrom(_msgSender(), address(this), tokenIds[i]);

      ownerTokensIndices[tokenIds[i]] = ownerTokens[_msgSender()].length;
      ownerTokens[_msgSender()].push(tokenIds[i]);

      if (_isVillager(tokenIds[i])) {
        _addVillagerToVillage(_msgSender(), tokenIds[i]);
      } else {
        _addVikingToRaidParty(_msgSender(), tokenIds[i]);
      }
    }
  }

  /**
   * realize $GOLD earnings and optionally unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param shouldUnstake whether or not to unstake the tokens
   */
  function claimEarnings(uint16[] calldata tokenIds, bool shouldUnstake) external nonReentrant whenNotPaused _updateEarnings {
    require(tx.origin == _msgSender() && !_msgSender().isContract(), "VILLAGE: Only EOA");

    uint256 totalEarned = 0;

    for (uint i = 0; i < tokenIds.length; i++) {
      require(vandv.ownerOf(tokenIds[i]) == address(this), "VILLAGE: Token not owned by village contract");

      if (_isVillager(tokenIds[i])) {
        totalEarned += _claimVillagerRewards(tokenIds[i], shouldUnstake);
      } else {
        totalEarned += _claimVikingRewards(tokenIds[i], shouldUnstake);
      }
    }

    if (totalEarned > 0) {
      gold.mint(_msgSender(), totalEarned);
    }
  }

  /**
   * get the token IDs owned by an address that are currently staked here
   * @param owner the owner's address
   * @return the token ids staked
   */
  function getTokensForOwner(address owner) external view returns (uint256[] memory) {
    require(owner == _msgSender(), "VILLAGE: Only the owner can check their tokens");

    return ownerTokens[owner];
  }

  /**
   * calculate the total $GOLD earnings for a staked token
   * @param tokenId the token ID
   * @return the total earnings
   */
  function getEarningsForToken(uint256 tokenId) external view returns (uint256) {
    uint256 owed = 0;

    if (_isVillager(tokenId)) {
      Stake memory stake = village[tokenId];

      require(stake.owner == _msgSender(), "VILLAGE: Only the owner can check their earnings");

      if (totalGoldEarned < MAXIMUM_GLOBAL_GOLD) {
        owed = (block.timestamp - stake.value) * DAILY_GOLD_RATE / 1 days;
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $GOLD production stopped already
      } else {
        owed = (lastClaimTimestamp - stake.value) * DAILY_GOLD_RATE / 1 days; // stop earning additional $GOLD if it's all been earned
      }
    } else {
      uint8 alpha = _alphaForViking(tokenId);
      Stake memory stake = parties[alpha][partyIndices[tokenId]];

      require(stake.owner == _msgSender(), "VILLAGE: Only the owner can check their earnings");

      owed = alpha * (rewardsPerAlpha - stake.value);
    }

    return owed;
  }

  /**
   * check if the owner can unstake a token
   * @param tokenId the token ID
   * @return whether the token can be unstaked
   */
  function canUnstake(uint256 tokenId) external view returns (bool) {
    if (_isVillager(tokenId)) {
      Stake memory stake = village[tokenId];

      require(stake.owner == _msgSender(), "VILLAGE: Only the owner can check their tokens");

      return block.timestamp - stake.value >= MINIMUM_TO_EXIT;
    } else {
      uint8 alpha = _alphaForViking(tokenId);
      Stake memory stake = parties[alpha][partyIndices[tokenId]];

      require(stake.owner == _msgSender(), "VILLAGE: Only the owner can check their tokens");

      return true;
    }
  }

  /**
   * used by the minting contract to find a randomly staked viking to award
   * a stolen villager to
   * @param seed a random value to choose a viking from
   * @return the owner of the viking
   */
  function randomVikingOwner(uint256 seed) external override view returns (address) {
    if (totalAlphaStaked == 0) {
      return address(0x0);
    }

    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
    uint256 cumulative;

    seed >>= 32;

    // loop through each bucket of vikings in parties until we find the correct bucket
    for (uint8 i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
      cumulative += parties[i].length * i;

      if (bucket >= cumulative) {
        continue;
      }

      return parties[i][seed % parties[i].length].owner;
    }

    return address(0x0);
  }

  /**
   * @param from the address that sent the token
   * @return whether the token should be accepted
   */
  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
    require(from == address(0x0), "VILLAGE: Cannot send tokens directly");

    return IERC721Receiver.onERC721Received.selector;
  }

  /**
   * set the address of our randomizer contract
   * @param _randomizer the address
   */
  function setRandomizer(address _randomizer) external onlyOwner {
    randomizer = IRandomizer(_randomizer);
  }

  /**
   * set the address of the gold contract
   * @param _gold the address
   */
  function setGold(address _gold) external onlyOwner {
    gold = IGOLD(_gold);
  }

  /**
   * set the address of the traits contract
   * @param _traits the address
   */
  function setTraits(address _traits) external onlyOwner {
    traits = ITraits(_traits);
  }

  /**
   * set the address of the V&V contract
   * @param _vandv the address
   */
  function setVAndV(address _vandv) external onlyOwner {
    vandv = VAndV(_vandv);
  }

  /**
   * enables owner to pause/unpause staking/claiming
   * @param enabled if we should pause or unpause
   */
  function setPaused(bool enabled) external onlyOwner {
    if (enabled) {
      _pause();
    } else {
      _unpause();
    }
  }

  /**
   * adds a villager to the village so they start producing $GOLD
   * @param owner the address of the staker
   * @param tokenId the token ID
   */
  function _addVillagerToVillage(address owner, uint256 tokenId) internal _updateEarnings {
    village[tokenId] = Stake({
      owner: owner,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });

    totalVillagersStaked += 1;
  }

  /**
   * adds a viking to the relevant raid party with the same alpha score
   * @param owner the address of the staker
   * @param tokenId the token ID
   */
  function _addVikingToRaidParty(address owner, uint256 tokenId) internal {
    uint8 alpha = _alphaForViking(tokenId);

    partyIndices[tokenId] = parties[alpha].length;

    parties[alpha].push(Stake({
      owner: owner,
      tokenId: uint16(tokenId),
      value: uint80(rewardsPerAlpha)
    }));

    totalVikingsStaked += 1;
    totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
  }

  /**
   * figure out how much $GOLD the villager earned and do some accounting
   * if not unstaking, pay a 20% tax to the staked vikings
   * if unstaking, there is a 50% chance all $GOLD is stolen
   * @param tokenId the ID of the villager to claim earnings from
   * @param shouldUnstake whether or not to unstake the villager
   * @return owed the amount of $GOLD earned
   */
  function _claimVillagerRewards(uint256 tokenId, bool shouldUnstake) internal returns (uint256 owed) {
    Stake memory stake = village[tokenId];

    require(stake.owner == _msgSender(), "VILLAGE: Unable to claim because wrong owner");

    if (shouldUnstake) {
      require(block.timestamp - stake.value >= MINIMUM_TO_EXIT, "VILLAGE: Can't unstake and claim yet");
    }

    if (totalGoldEarned < MAXIMUM_GLOBAL_GOLD) {
      owed = (block.timestamp - stake.value) * DAILY_GOLD_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $GOLD production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_GOLD_RATE / 1 days; // stop earning additional $GOLD if it's all been earned
    }

    if (shouldUnstake) {
      // 50% chance that all $GOLD is stolen by vikings
      if (randomizer.random(tokenId) & 1 == 1) {
        _addTaxedRewards(owed);
        emit GoldStolen(_msgSender(), owed);
        owed = 0;
      }

      delete village[tokenId];

      uint256 lastTokenId = ownerTokens[_msgSender()][ownerTokens[_msgSender()].length - 1];
      ownerTokens[_msgSender()][ownerTokensIndices[tokenId]] = lastTokenId;
      ownerTokensIndices[lastTokenId] = ownerTokensIndices[tokenId];
      ownerTokens[_msgSender()].pop();
      delete ownerTokensIndices[tokenId];

      totalVillagersStaked -= 1;

      vandv.safeTransferFrom(address(this), _msgSender(), tokenId, "");
    } else {
      uint256 tax = owed * GOLD_CLAIM_TAX_PERCENTAGE / 100;
      _addTaxedRewards(tax);
      emit GoldTaxed(_msgSender(), tax);
      owed -= tax;

      // reset the stake timestamp
      village[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      });
    }
  }

  /**
   * claim earned $GOLD for staked vikings
   * @param tokenId the ID of the viking to claim earnings from
   * @param shouldUnstake whether or not to unstake the viking
   * @return owed the amount of $GOLD earned
   */
  function _claimVikingRewards(uint256 tokenId, bool shouldUnstake) internal returns (uint256 owed) {
    uint8 alpha = _alphaForViking(tokenId);
    Stake memory stake = parties[alpha][partyIndices[tokenId]];

    require(stake.owner == _msgSender(), "VILLAGE: Unable to claim because wrong owner");

    owed = alpha * (rewardsPerAlpha - stake.value);

    if (shouldUnstake) {
      Stake memory lastStake = parties[alpha][parties[alpha].length - 1];
      parties[alpha][partyIndices[tokenId]] = lastStake;
      partyIndices[lastStake.tokenId] = partyIndices[tokenId];
      parties[alpha].pop();
      delete partyIndices[tokenId];

      uint256 lastTokenId = ownerTokens[_msgSender()][ownerTokens[_msgSender()].length - 1];
      ownerTokens[_msgSender()][ownerTokensIndices[tokenId]] = lastTokenId;
      ownerTokensIndices[lastTokenId] = ownerTokensIndices[tokenId];
      ownerTokens[_msgSender()].pop();
      delete ownerTokensIndices[tokenId];

      totalVikingsStaked -= 1;
      totalAlphaStaked -= alpha;

      vandv.safeTransferFrom(address(this), _msgSender(), tokenId, "");
    } else {
      // reset the stake timestamp
      parties[alpha][partyIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(rewardsPerAlpha)
      });
    }
  }

  /**
   * do some accounting to add the $GOLD taxed from villagers when they
   * claim their earnings
   * @param amount the total $GOLD to add to the unclaimed rewards
   */
  function _addTaxedRewards(uint256 amount) internal {
    // if there's no staked vikings keep track of the gold
    if (totalAlphaStaked == 0) {
      unaccountedRewards += amount;
      return;
    }

    rewardsPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
    unaccountedRewards = 0;
  }

  /**
   * checks if a token is a villager
   * @param tokenId the ID of the token to check
   * @return whether the token is a villager
   */
  function _isVillager(uint256 tokenId) internal view returns (bool) {
    return traits.getTokenTraits(tokenId).isVillager;
  }

  /**
   * gets the alpha score for a viking
   * @param tokenId the token ID to check
   * @return the alpha score from 5-8
   */
  function _alphaForViking(uint256 tokenId) internal view returns (uint8) {
    return MAX_ALPHA - traits.getTokenTraits(tokenId).alphaIndex;
  }

  /**
   * make this function calculate the total $GOLD earned by villagers and
   * ensure we never go beyond the earnings cap
   */
  modifier _updateEarnings() {
    if (totalGoldEarned < MAXIMUM_GLOBAL_GOLD) {
      totalGoldEarned += (block.timestamp - lastClaimTimestamp) * totalVillagersStaked * DAILY_GOLD_RATE / 1 days;
      lastClaimTimestamp = block.timestamp;
    }

    _;
  }

}
