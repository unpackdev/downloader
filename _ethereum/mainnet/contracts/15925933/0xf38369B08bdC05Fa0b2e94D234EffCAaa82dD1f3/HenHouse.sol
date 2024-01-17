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

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IEGGToken.sol";
import "./IEggShop.sol";
import "./IFarmAnimals.sol";
import "./IHenHouse.sol";
import "./IHenHouseCalc.sol";
import "./IHenHouseAdvantage.sol";
import "./ITheFarmGameMint.sol";
import "./IRandomizer.sol";

contract HenHouse is IHenHouse, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  // Events
  event InitializedContract(address thisContract);
  event TokenStaked(
    address indexed owner,
    uint256 indexed tokenId,
    string kind,
    uint256 eggPerRank,
    uint256 stakedTimestamp,
    uint256 unstakeTimestamp
  );
  event EggClaimedUnstaked(
    uint256 indexed tokenId,
    bool indexed unstaked,
    string kind,
    uint256 earned,
    uint256 unstakeTimestamp
  );
  event RoosterReceivedDroppedEgg(address indexed owner, uint256 indexed tokenId, uint256 amount);
  event GoldenEggAwarded(address indexed recipient);

  // Interfaces
  IEggShop public eggShop; // ref to the EggShop contract
  IEGGToken public eggToken; // ref to the $EGG contract for minting $EGG earnings
  IFarmAnimals public farmAnimalsNFT; // ref to the FarmAnimals NFT contract
  IHenHouseAdvantage public henHouseAdvantage; // ref to HenHouseAdvantage contract
  IHenHouseCalc public henHouseCalc; // ref to HenHouseCalc contract
  ITheFarmGameMint public theFarmGameMint; // ref to the TheFarmGameMint contract
  IRandomizer public randomizer; // ref to the EggShop contract

  mapping(address => bool) private controllers; // address => allowedToCallFunctions

  mapping(address => uint256[]) public stakedNFTs; // mapping from user address to Token List
  mapping(uint256 => uint256) public stakedNFTsIndices;

  uint8 public constant MAX_RANK = 5; // Maximum rank for a Hen/Coyote/Rooster

  // Hens
  uint256 public constant DAILY_EGG_RATE = 10000 ether; // Hens earn 10000 $EGG per day
  uint256 private numHensStaked; // Track staked hens
  uint256 public totalEGGEarnedByHen; // Amount of $EGG earned so far
  uint256 private lastClaimTimestampByHen; // The last time $EGG was claimed
  mapping(uint256 => Stake) public henHouse; // Maps tokenId to stake in henHouse
  uint256 public HEN_MINIMUM_TO_EXIT = 2 days; // hens must have 2 days worth of $EGG quota to unstake

  // Coyotes
  uint256 private numCoyotesStaked;
  uint256 private totalCoyoteRankStaked;
  uint256 private eggPerCoyoteRank = 0; // Amount of tax $EGG due per Wily rank point staked
  uint256 private unaccountedCoyoteTax = 0; // Any EGG distributed when no coyotes are staked
  uint256 public dropCoyoteRate = 40; // $EGG drop rate to coyote when hen claim their reward $EGG token
  uint256 public constant COYOTE_TAX = 20; // Coyotes take a 20% tax on all $EGG claimed by Hens
  mapping(uint256 => Stake[]) private den; // Maps rank to all Coyote staked with that rank
  mapping(uint256 => uint256) private denIndices; // Tracks location of each Coyote in Den

  // Roosters
  uint256 private numRoostersStaked;
  uint256 private totalRoosterRankStaked;
  uint256 private eggPerRoosterRank = 0; // Amount of dialy $EGG due per Guard rank point staked
  uint256 private rescueEggPerRank = 0; // Amunt of rescued $EGG due per Guard rank staked
  uint256 public totalEGGEarnedByRooster; // amount of $EGG earned so far
  uint256 private lastClaimTimestampByRooster;
  mapping(uint256 => Stake[]) private guardHouse; // Maps rank to all Roosters staked with that rank
  mapping(uint256 => uint256) private guardHouseIndices; // Tracks location of each Rooster in Guard house
  uint256 public constant DAILY_ROOSTER_EGG_RATE = 1000 ether; // Rooster earn 1000 ether per day on guard duty
  uint256 public ROOSTER_MUG_RATE = 30; // Coyotes have a 10% chance of taking 30% of the rooster's claimed $EGG when unstake
  uint256 public ROOSTER_MINIMUM_TO_EXIT = 5 days; // Roosters must have 5 days worth of $EGG quota to unstake

  // Recource tracking
  uint256 public constant MAXIMUM_GLOBAL_EGG = 2880000000 ether; // there will only ever be (roughly) 2.88 billion $EGG earned through staking
  uint256 public rescuedEggPool; // Rescue EGG token pool from EGG transfer tax
  uint256 public rescuedEggPoolRate = 20; // Rate to separate the amount of tokens coming from EggToken Contract for RescuedEggPool
  uint256 public genericEggPool; // Generic EGG token pool from EGG transfer tax
  uint256 public genericEggPoolRate = 8; // Rate to separate the amount of tokens coming from EggToken Contract for GenericEggPool

  // Egg Shop
  uint256 public goldenEggTypeId = 4; // EggShop Golden Egg Type Id
  uint256 public goldenRate = 60;
  uint256 private lastGoldenClaimedTimestamp; // the last time Golden Egg claimed
  uint256 private goldenCountPerDay;

  bool public rescueEnabled = false; // emergency rescue to allow unstaking without any checks but without $EGG

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

  constructor(
    IEGGToken _eggToken,
    IFarmAnimals _farmAnimalsNFT,
    IRandomizer _randomizer,
    IEggShop _eggshop,
    IHenHouseAdvantage _henHouseAdvantage,
    IHenHouseCalc _henHouseCalc
  ) {
    eggToken = _eggToken;
    farmAnimalsNFT = _farmAnimalsNFT;
    randomizer = _randomizer;
    eggShop = _eggshop;
    henHouseAdvantage = _henHouseAdvantage;
    henHouseCalc = _henHouseCalc;

    lastGoldenClaimedTimestamp = block.timestamp;

    controllers[_msgSender()] = true;
    controllers[address(farmAnimalsNFT)] = true;
    controllers[address(henHouseCalc)] = true;

    _pause();
    emit InitializedContract(address(this));
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
   * @notice Adds a single Hen to the HenHouse
   * @param account the address of the staker
   * @param tokenId the ID of the Hen to add to the HenHouse
   */
  function _addHenToHenHouse(address account, uint256 tokenId) internal _updateEarnings {
    uint256 unstakeTimestamp = block.timestamp + HEN_MINIMUM_TO_EXIT;
    henHouse[tokenId] = Stake({
      tokenId: uint16(tokenId),
      owner: account,
      eggPerRank: uint80(block.timestamp),
      rescueEggPerRank: 0,
      oneOffEgg: 0,
      stakedTimestamp: block.timestamp,
      unstakeTimestamp: unstakeTimestamp
    });
    numHensStaked = numHensStaked + 1;
    emit TokenStaked(account, tokenId, 'HEN', DAILY_EGG_RATE, block.timestamp, unstakeTimestamp);
  }

  /**
   * @notice Adds a single Coyote to the Den
   * @param account the address of the staker
   * @param tokenId the ID of the Coyote to add to the Den
   */
  function _addCoyoteToDen(address account, uint256 tokenId) internal {
    uint8 rank = _rankForCoyoteRooster(tokenId);

    totalCoyoteRankStaked = totalCoyoteRankStaked + rank; // Portion of earnings ranges from 8 to 5
    denIndices[tokenId] = den[rank].length; // Store the location of the coyote in the Den
    den[rank].push(
      Stake({
        tokenId: uint16(tokenId),
        owner: account,
        eggPerRank: uint80(eggPerCoyoteRank),
        rescueEggPerRank: 0,
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: block.timestamp
      })
    ); // Add the coyote to the Den
    numCoyotesStaked = numCoyotesStaked + 1;
    emit TokenStaked(account, tokenId, 'COYOTE', eggPerCoyoteRank, block.timestamp, block.timestamp);
  }

  /**
   * @notice Adds a single Rooster to the Guard house
   * @param account the address of the staker
   * @param tokenId the ID of the Rooster to add to the Guard house
   */
  function _addRoosterToGuardHouse(address account, uint256 tokenId) internal {
    uint256 rank = uint256(_rankForCoyoteRooster(tokenId));
    uint256 unstakeTimestamp = block.timestamp + ROOSTER_MINIMUM_TO_EXIT;
    totalRoosterRankStaked = totalRoosterRankStaked + rank; // Portion of earnings ranges from 8 to 5
    guardHouseIndices[tokenId] = guardHouse[rank].length; // Store the location of the rooster in the Guard house
    guardHouse[rank].push(
      Stake({
        tokenId: uint16(tokenId),
        owner: account,
        eggPerRank: uint80(eggPerRoosterRank),
        rescueEggPerRank: uint80(rescueEggPerRank),
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: unstakeTimestamp
      })
    ); // Add the rooster to the Guard house

    numRoostersStaked = numRoostersStaked + 1;

    emit TokenStaked(account, tokenId, 'ROOSTER', eggPerRoosterRank, block.timestamp, unstakeTimestamp);
  }

  /**
   * @notice Realize $EGG earnings for a single Hen and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Coyotes
   * if unstaking, there is a 50% chance all $EGG is stolen
   * @param tokenId the ID of the Hens to claim earnings from
   * @param unstake whether or not to unstake the Hens
   * @return owed - the amount of $EGG earned
   */
  function _claimHenFromHenHouse(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = henHouse[tokenId];

    require(stake.owner == tx.origin, 'Caller not owner');
    owed = henHouseCalc.calculateRewardsHen(tokenId, stake);
    henHouseAdvantage.updateAdvantageBonus(tokenId);

    if (unstake) {
      require(block.timestamp > stake.unstakeTimestamp, 'Need the min EGG quota to unstake');
      if (randomizer.random() & 1 == 1) {
        // 50% chance of all $EGG stolen
        _payCoyoteTax(owed);
        owed = 0;
      }

      delete henHouse[tokenId];
      henHouseAdvantage.removeAdvantageBonus(tokenId); // delete production bonus of tokenId when unstaked
      numHensStaked = numHensStaked + 1;
      // Always transfer last to guard against reentrance
      farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // send back Hen
      _removeStakedAddress(_msgSender(), tokenId);
    } else {
      uint256 henCoyoteTax = (owed * COYOTE_TAX) / 100;
      _payCoyoteTax(henCoyoteTax); // percentage tax to staked coyotes
      owed = owed - henCoyoteTax; // remainder goes to Hen owner
      uint256 unstakeTimestamp = block.timestamp + HEN_MINIMUM_TO_EXIT;
      henHouse[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        eggPerRank: uint80(block.timestamp),
        rescueEggPerRank: 0,
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: unstakeTimestamp
      }); // reset stake
    }
    emit EggClaimedUnstaked(tokenId, unstake, 'HEN', owed, block.timestamp + HEN_MINIMUM_TO_EXIT);
  }

  /**
   * @notice Realize $EGG earnings for a single Coyote and optionally unstake it
   * Coyotes earn $EGG proportional to their rank
   * @param tokenId the ID of the Coyote to claim earnings from
   * @param unstake whether or not to unstake the Coyote
   * @return owed - the amount of $EGG earned
   */
  function _claimCoyoteFromDen(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    uint8 rank = _rankForCoyoteRooster(tokenId);
    owed = henHouseCalc.calculateRewardsCoyote(tokenId, rank);

    henHouseAdvantage.updateAdvantageBonus(tokenId);

    // If there are roosters then chance that one may rescues some dropped EGGs
    if (randomizer.random() & 10 == 1 && numRoostersStaked > 0) {
      // Calculate 10% chance coyote drops some egg
      uint256 dAmount = _calcCoyoteDropRate(owed); // Calculate the Drop Amount Egg of owned
      owed = owed - dAmount; // Remove Drop Amount of owned
      _coyoteDropEggToRooster(tokenId, dAmount);
    }

    if (unstake) {
      totalCoyoteRankStaked = totalCoyoteRankStaked - rank; // Remove rank from total staked
      Stake memory lastStake = den[rank][den[rank].length - 1];
      den[rank][denIndices[tokenId]] = lastStake; //  Shuffle last Coyote to current position
      denIndices[lastStake.tokenId] = denIndices[tokenId];
      den[rank].pop(); // Remove duplicate
      delete denIndices[tokenId]; // Delete old mapping
      henHouseAdvantage.removeAdvantageBonus(tokenId); // Delete old mapping
      numCoyotesStaked = numCoyotesStaked - 1;
      // Always remove last to guard against reentrance
      farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Coyote
      _removeStakedAddress(_msgSender(), tokenId);
    } else {
      den[rank][denIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        eggPerRank: uint80(eggPerCoyoteRank),
        rescueEggPerRank: 0,
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: block.timestamp
      }); // reset stake
    }
    emit EggClaimedUnstaked(tokenId, unstake, 'COYOTE', owed, block.timestamp);
  }

  /**
   * @notice Realize $EGG earnings for a single Rooster and optionally unstake it
   * Rooster earn $EGG proportional to their rank
   * @param tokenId the ID of the Rooster to claim earnings from
   * @param unstake whether or not to unstake the Rooster
   * @return owed - the amount of $EGG earned
   */
  function _claimRoosterFromGuardHouse(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    uint8 rank = _rankForCoyoteRooster(tokenId);
    Stake memory stake = guardHouse[rank][guardHouseIndices[tokenId]];
    require(stake.owner == tx.origin, 'Caller not owner');

    owed = henHouseCalc.calculateRewardsRooster(tokenId, rank, stake);

    henHouseAdvantage.updateAdvantageBonus(tokenId);

    if (unstake) {
      require(block.timestamp > stake.unstakeTimestamp, 'Roosters should finish 5 days of guard duty');
      // Roosters 10% chance pay 30% tax to coyotes
      if (randomizer.random() & 10 == 1) {
        uint256 roosterCoyoteTax = (owed * ROOSTER_MUG_RATE) / 100;
        _payCoyoteTax(roosterCoyoteTax); // percentage tax to staked coyotes
        owed = owed - roosterCoyoteTax;
      }

      totalRoosterRankStaked -= rank; // Remove rank from total staked
      Stake memory lastStake = guardHouse[rank][guardHouse[rank].length - 1];
      guardHouse[rank][guardHouseIndices[tokenId]] = lastStake; // Shuffle last Rooster to current position
      guardHouseIndices[lastStake.tokenId] = guardHouseIndices[tokenId];
      guardHouse[rank].pop(); // Remove duplicate
      delete guardHouseIndices[tokenId]; // Delete old mapping
      henHouseAdvantage.removeAdvantageBonus(tokenId); // Delete old mapping
      numRoostersStaked = numRoostersStaked - 1;
      // Always remove last to guard against reentrance
      farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Rooster
      _removeStakedAddress(_msgSender(), tokenId);
    } else {
      uint256 unstakeTimestamp = block.timestamp + ROOSTER_MINIMUM_TO_EXIT;
      guardHouse[rank][guardHouseIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        eggPerRank: uint80(eggPerRoosterRank),
        rescueEggPerRank: uint80(rescueEggPerRank),
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: unstakeTimestamp
      }); // reset stake
    }
    emit EggClaimedUnstaked(tokenId, unstake, 'ROOSTER', owed, block.timestamp + ROOSTER_MINIMUM_TO_EXIT);
  }

  /**
   * @notice Get token kind (chicken, coyote, rooster)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(uint256 tokenId) internal view returns (IFarmAnimals.Kind) {
    return farmAnimalsNFT.getTokenTraits(tokenId).kind;
  }

  /** ACCOUNTING */

  /**
   * @notice Add $EGG to claimable pot for the Coyote Den
   * @param amount $EGG to add to the pot
   */
  function _payCoyoteTax(uint256 amount) internal {
    if (totalCoyoteRankStaked == 0) {
      // if there's no staked coyotes
      unaccountedCoyoteTax += amount; // keep track of $EGG due to coyotes
      return;
    }
    // makes sure to include any unaccounted $EGG
    eggPerCoyoteRank += (amount + unaccountedCoyoteTax) / totalCoyoteRankStaked;
    unaccountedCoyoteTax = 0;
  }

  /**
   * @notice Add Dropped $EGG amount to a randome Rooster
     @param tokenId the ID of the Coyote to claim earnings from
   * @param amount $EGG amount of dropped from Coyote
   */

  function _coyoteDropEggToRooster(uint256 tokenId, uint256 amount) internal {
    uint256 seed = randomizer.randomToken(tokenId);
    uint256 roosterTokenId = randomRoosterTokenId(seed); // Get a random rooster
    uint8 rank = _rankForCoyoteRooster(roosterTokenId); // Rank for the random rooster
    Stake storage stake = guardHouse[rank][guardHouseIndices[roosterTokenId]]; // Grab the rooster to update

    uint256 accruedOneOffEgg = stake.oneOffEgg;
    accruedOneOffEgg += amount;
    stake.oneOffEgg = accruedOneOffEgg;
    emit RoosterReceivedDroppedEgg(stake.owner, stake.tokenId, amount);
  }

  /**
   * @notice Gets the rank score for a Coyote
   * @param tokenId the ID of the Coyote to get the rank score for
   * @return the rank score of the Coyote & Rooster(5-8)
   */
  function _rankForCoyoteRooster(uint256 tokenId) internal view returns (uint8) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return uint8(s.advantage + 1); // rank index is 0-4
  }

  /**
   * @notice Tracks $EGG earnings to ensure it stops once max $EGG Token is eclipsed
   */
  modifier _updateEarnings() {
    if ((totalEGGEarnedByHen + totalEGGEarnedByRooster) < MAXIMUM_GLOBAL_EGG) {
      // update hen
      totalEGGEarnedByHen += ((block.timestamp - lastClaimTimestampByHen) * numHensStaked * DAILY_EGG_RATE) / 1 days;
      lastClaimTimestampByHen = block.timestamp;

      // update rooster
      totalEGGEarnedByRooster +=
        ((block.timestamp - lastClaimTimestampByRooster) * numRoostersStaked * DAILY_ROOSTER_EGG_RATE) /
        1 days;
      lastClaimTimestampByRooster = block.timestamp;
    }

    _calcEggPerRankOfRooster();
    _;
  }

  /**
   * @notice calc the rescuedEggPool, genericEggPool from the Contract $Egg Balance.
   */
  function _calcEggPerRankOfRooster() internal {
    // Only calculate if there is Roosters staked
    if (numRoostersStaked > 0 && rescuedEggPool > 0) {
      uint256 balance = eggToken.balanceOf(address(this));
      // If HenHouse has an $EGG token balance from transfer tax, include that in updated pool calcs
      if (balance > 0) {
        uint256 _extraRescuedEggPool = (balance * rescuedEggPoolRate) / (rescuedEggPoolRate + genericEggPoolRate);
        rescuedEggPool += _extraRescuedEggPool;

        uint256 _extraGenericEggPool = balance - _extraRescuedEggPool;

        genericEggPool += _extraGenericEggPool;

        eggToken.burn(address(this), balance);
      }

      rescueEggPerRank += rescuedEggPool / totalRoosterRankStaked; // Recalculate eggRankForRooster
      // rescueEggPerRank += rescuedEggPool / numRoostersStaked; // Recalculate eggRankForRooster
      rescuedEggPool = 0; // Since rescuedEggPool added to EggRankForRooster, reset pool to 0
    }
  }

  /**
   * @notice Get drop amount from Coyote by dropCoyoteRate
     @param amount claim amount for calculating drop amount from coyote
   */

  function _calcCoyoteDropRate(uint256 amount) internal view returns (uint256) {
    return (amount * dropCoyoteRate) / (10**2);
  }

  /** @notice Mint a golen egg token to receipt
   * @param receipt receipt address to get golden token
   */

  function _awardGoldenEgg(address receipt) internal {
    if (block.timestamp - lastGoldenClaimedTimestamp <= 1 days) {
      uint256 randomRate = randomizer.random() % 100;
      if (goldenCountPerDay < 24 && (randomRate < goldenRate)) {
        eggShop.mint(goldenEggTypeId, 1, receipt, uint256(0));
        goldenCountPerDay += 1;
        emit GoldenEggAwarded(receipt);
      } else {
        lastGoldenClaimedTimestamp = block.timestamp;
        goldenCountPerDay = 0;
      }
    }
  }

  /** @notice Remove the staked info from HenHouse staked history list by token owner
   * @param stakedOwner Owner address of staked NFT
   * @param tokenId Token Id to remove the staked info from HenHouse
   */

  function _removeStakedAddress(address stakedOwner, uint256 tokenId) internal {
    uint256 lastStakedNFTs = stakedNFTs[stakedOwner][stakedNFTs[stakedOwner].length - 1];
    stakedNFTs[stakedOwner][stakedNFTsIndices[tokenId]] = lastStakedNFTs;
    stakedNFTsIndices[stakedNFTs[stakedOwner][stakedNFTs[stakedOwner].length - 1]] = stakedNFTsIndices[tokenId];
    stakedNFTs[_msgSender()].pop();
    delete stakedNFTsIndices[tokenId];
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /** STAKING */

  /**
   * @notice Adds Hens, Coyotes & Roosters to the Hen House, Den & Guard house
   * @param account the address of the staker
   * @param tokenIds the IDs of the Hens, Coyotes or Roosters to stake
   */
  function addManyToHenHouse(address account, uint16[] calldata tokenIds) external override nonReentrant whenNotPaused {
    require(tx.origin == _msgSender() || _msgSender() == address(theFarmGameMint), 'Only EOA');
    require(account == tx.origin, 'Account to sender mismatch');
    uint256 max = tokenIds.length;
    for (uint256 i = 0; i < max; ) {
      if (_msgSender() != address(theFarmGameMint)) {
        // dont do this step if its a mint + stake
        require(farmAnimalsNFT.ownerOf(tokenIds[i]) == _msgSender(), 'Caller not owner');
        farmAnimalsNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        // shortcircuit no tokenId, this accounts for stolen tokens

        unchecked {
          i++;
        }
        continue;
      }

      IFarmAnimals.Kind kind = _getKind(tokenIds[i]);

      if (kind == IFarmAnimals.Kind.HEN) {
        _addHenToHenHouse(account, tokenIds[i]);
      } else if (kind == IFarmAnimals.Kind.COYOTE) {
        _addCoyoteToDen(account, tokenIds[i]);
      } else if (kind == IFarmAnimals.Kind.ROOSTER) {
        _addRoosterToGuardHouse(account, tokenIds[i]);
      }
      stakedNFTs[account].push(tokenIds[i]);
      stakedNFTsIndices[tokenIds[i]] = stakedNFTs[account].length - 1;

      henHouseAdvantage.updateAdvantageBonus(tokenIds[i]);
      unchecked {
        i++;
      }
    }
  }

  /** CLAIMING / UNSTAKING */

  /**
   * @notice Check if tokenID is eligible to be unstaked
   * @param tokenId the ID of the Rooster to claim earnings from
   * @return bool - true/false
   */
  function canUnstake(uint16 tokenId) external view returns (bool) {
    bool canUnstak = false;
    if (paused() == true) return false;
    IFarmAnimals.Kind kind = _getKind(tokenId);
    if (kind == IFarmAnimals.Kind.HEN) {
      Stake memory stake = henHouse[tokenId];
      if (stake.unstakeTimestamp <= block.timestamp) {
        canUnstak = true;
      }
    } else if (kind == IFarmAnimals.Kind.COYOTE) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      Stake memory stake = den[rank][denIndices[tokenId]];
      if (stake.unstakeTimestamp <= block.timestamp) {
        canUnstak = true;
      }
    } else if (kind == IFarmAnimals.Kind.ROOSTER) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      Stake memory stake = guardHouse[rank][guardHouseIndices[tokenId]];
      if (stake.unstakeTimestamp <= block.timestamp) {
        canUnstak = true;
      }
    }
    return canUnstak;
  }

  /**
   * @notice Realize $EGG earnings and optionally unstake tokens from the HenHouse / Den
   * to unstake a Hen it will require it has 2 days worth of $EGG unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromHenHouseAndDen(uint16[] calldata tokenIds, bool unstake)
    external
    whenNotPaused
    _updateEarnings
    nonReentrant
  {
    require(tx.origin == _msgSender() || _msgSender() == address(theFarmGameMint), 'Only EOA');
    uint256 owed = 0;
    uint256 max = tokenIds.length;
    for (uint256 i = 0; i < max; ) {
      require(farmAnimalsNFT.ownerOf(tokenIds[i]) == address(this), 'Hen House not owner');
      if (tx.origin == _msgSender()) {
        IEggShop.TypeInfo memory goldenTypeInfo = eggShop.getInfoForType(goldenEggTypeId);
        if ((goldenTypeInfo.mints + goldenTypeInfo.burns) <= goldenTypeInfo.maxSupply) {
          _awardGoldenEgg(_msgSender());
        }
      }
      IFarmAnimals.Kind kind = _getKind(tokenIds[i]);
      if (kind == IFarmAnimals.Kind.HEN) {
        owed = owed + (_claimHenFromHenHouse(tokenIds[i], unstake));
      } else if (kind == IFarmAnimals.Kind.COYOTE) {
        owed = owed + (_claimCoyoteFromDen(tokenIds[i], unstake));
      } else if (kind == IFarmAnimals.Kind.ROOSTER) {
        owed = owed + (_claimRoosterFromGuardHouse(tokenIds[i], unstake));
      }
      unchecked {
        i++;
      }
    }
    if (owed == 0) {
      return;
    }
    eggToken.mint(_msgSender(), owed);
  }

  /**
   * @notice Emergency unstake tokens
   * @param tokenIds the IDs of the tokens to rescue, egg earnings are lost
   */
  function rescue(uint16[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, 'RESCUE DISABLED');
    uint256 tokenId;
    uint8 rank;

    uint256 max = tokenIds.length;
    for (uint256 i = 0; i < max; ) {
      tokenId = tokenIds[i];

      IFarmAnimals.Kind kind = _getKind(tokenId);

      if (kind == IFarmAnimals.Kind.HEN) {
        Stake memory stake;
        stake = henHouse[tokenId];
        require(stake.owner == _msgSender(), 'Caller not owner');
        delete henHouse[tokenId];
        numHensStaked = numHensStaked - 1;
        farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // send back Hens
        emit EggClaimedUnstaked(tokenId, true, 'HEN', 0, block.timestamp);
      } else if (kind == IFarmAnimals.Kind.COYOTE) {
        rank = _rankForCoyoteRooster(tokenId);
        Stake memory stake = den[rank][denIndices[tokenId]];
        Stake memory lastStake;
        require(stake.owner == _msgSender(), 'Caller not owner');
        totalCoyoteRankStaked -= rank; // Remove Rank from total staked
        lastStake = den[rank][den[rank].length - 1];
        den[rank][denIndices[tokenId]] = lastStake; // Shuffle last Coyote to current position
        denIndices[lastStake.tokenId] = denIndices[tokenId];
        den[rank].pop(); // Remove duplicate
        delete denIndices[tokenId]; // Delete old mapping
        numCoyotesStaked = numCoyotesStaked - 1;
        farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Coyote
        emit EggClaimedUnstaked(tokenId, true, 'COYOTE', 0, block.timestamp);
      } else if (kind == IFarmAnimals.Kind.ROOSTER) {
        Stake memory stake;
        Stake memory lastStake;
        rank = _rankForCoyoteRooster(tokenId);
        stake = guardHouse[rank][guardHouseIndices[tokenId]];
        require(stake.owner == _msgSender(), 'Caller not owner');
        totalRoosterRankStaked -= rank; // Remove Rank from total staked
        lastStake = guardHouse[rank][guardHouse[rank].length - 1];
        guardHouse[rank][guardHouseIndices[tokenId]] = lastStake; // Shuffle last Rooster to current position
        guardHouseIndices[lastStake.tokenId] = guardHouseIndices[tokenId];
        guardHouse[rank].pop(); // Remove duplicate
        delete guardHouseIndices[tokenId]; // Delete old mapping
        numRoostersStaked = numRoostersStaked - 1;
        farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Rooster
        emit EggClaimedUnstaked(tokenId, true, 'ROOSTER', 0, block.timestamp);
      }
      unchecked {
        i++;
      }
    }
  }

  /** READ ONLY */

  /**
   * @notice Get stake info for a token
   * @param tokenId the ID of the token to check
   * @return Stake struct info
   */
  function getStakeInfo(uint256 tokenId) external view returns (Stake memory) {
    IFarmAnimals.Kind kind = _getKind(tokenId);
    if (kind == IFarmAnimals.Kind.HEN) {
      return henHouse[tokenId];
    } else if (kind == IFarmAnimals.Kind.COYOTE) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      return den[rank][denIndices[tokenId]];
    } else {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      return guardHouse[rank][guardHouseIndices[tokenId]];
    }
  }

  /**
   * @notice Return staked nfts token id list
   * @param account the address of the staker
   */

  function getStakedByAddress(address account) external view returns (uint256[] memory) {
    return stakedNFTs[account];
  }

  /**
   * @notice Chooses a random Coyote thief when a newly minted token is stolen
   * @param seed a random value to choose a Coyote from
   * @return the owner address of the randomly selected Coyote thief
   */
  function randomCoyoteOwner(uint256 seed) external view override returns (address) {
    if (totalCoyoteRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalCoyoteRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Coyotes with the same rank score
    for (uint256 i = MAX_RANK - 5; i <= MAX_RANK; i++) {
      cumulative += den[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Coyote with that rank score
      return den[i][seed % den[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * @notice Chooses a random Rooster rescuer when claim $EGG token of coyote is dropped
   * @param seed a random value to choose a Rooster from
   * @return the owner address of the randomly selected Rooster rescuer
   */

  function randomRoosterOwner(uint256 seed) external view returns (address) {
    if (totalRoosterRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRoosterRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Roosters with the same rank score
    for (uint256 i = MAX_RANK - 5; i <= MAX_RANK; i++) {
      cumulative += guardHouse[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the token id of a random Rooster with that rank score
      return guardHouse[i][seed % guardHouse[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * @notice Chooses a random Rooster rescuer when claim $EGG token of coyote is dropped
   * @param seed a random value to choose a Rooster from
   * @return the token id of the randomly selected Rooster rescuer
   */

  function randomRoosterTokenId(uint256 seed) internal view returns (uint256) {
    if (totalRoosterRankStaked == 0) {
      return 0;
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRoosterRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Roosters with the same rank score
    for (uint256 i = MAX_RANK - 5; i <= MAX_RANK; i++) {
      cumulative += guardHouse[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the token id of a random Rooster with that rank score
      return guardHouse[i][seed % guardHouse[i].length].tokenId;
    }
    return 0;
  }

  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    require(from == address(0x0), 'Cannot send directly');
    return IERC721Receiver.onERC721Received.selector;
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
   * @notice Allows owner to enable "rescue mode"
   * @dev Simplifies accounting, prioritizes tokens out in emergency, only callable by owner
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
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
   * @notice Get info for Hen House data
   * @return Hen House staking info
   */
  function getHenHouseInfo() external view onlyController returns (HenHouseInfo memory) {
    HenHouseInfo memory henHouseInfo = HenHouseInfo({
      numHensStaked: numHensStaked,
      totalEGGEarnedByHen: totalEGGEarnedByHen,
      lastClaimTimestampByHen: lastClaimTimestampByHen
    });
    return henHouseInfo;
  }

  /**
   * @notice Get info for Den data
   * @return Den staking info
   */
  function getDenInfo() external view onlyController returns (DenInfo memory) {
    DenInfo memory denInfo = DenInfo({
      numCoyotesStaked: numCoyotesStaked,
      totalCoyoteRankStaked: totalCoyoteRankStaked,
      eggPerCoyoteRank: eggPerCoyoteRank
    });
    return denInfo;
  }

  /**
   * @notice Get info for Guard House data
   * @return Guard House staking info
   */
  function getGuardHouseInfo() external view onlyController returns (GuardHouseInfo memory) {
    GuardHouseInfo memory guardHouseInfo = GuardHouseInfo({
      numRoostersStaked: numRoostersStaked,
      totalRoosterRankStaked: totalRoosterRankStaked,
      totalEGGEarnedByRooster: totalEGGEarnedByRooster,
      lastClaimTimestampByRooster: lastClaimTimestampByRooster,
      eggPerRoosterRank: eggPerRoosterRank,
      rescueEggPerRank: rescueEggPerRank
    });
    return guardHouseInfo;
  }

  /**
   * @notice Add $EGG amount to rescuedPool
   * @dev Only callable by an existing controller
   */

  function addRescuedEggPool(uint256 _amount) external onlyController _updateEarnings {
    rescuedEggPool += _amount;
  }

  /**
   * @notice Add $EGG amount to rescuedPool
   * @dev Only callable by an existing controller
   */

  function addGenericEggPool(uint256 _amount) external onlyController _updateEarnings {
    genericEggPool += _amount;
  }

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
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
   * @notice Enables owner to pause / unpause contract
   * @dev Only callable by an existing controller
   */
  function setPaused(bool _paused) external onlyController {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * @notice Set multiple contract addresses
   * @dev Only callable by an existing controller
   * @param _eggShop Address of eggShop contract
   * @param _eggToken Address of eggToken contract
   * @param _farmAnimalsNFT Address of farmAnimals contract
   * @param _henHouseAdvantage Address of henHouseAdvantage contract
   * @param _henHouseCalc Address of henHouseCalc contract
   * @param _theFarmGameMint Address of theFarmGameMint contract
   * @param _randomizer Address of randomizer contract
   */

  function setExtContracts(
    address _eggShop,
    address _eggToken,
    address _farmAnimalsNFT,
    address _henHouseAdvantage,
    address _henHouseCalc,
    address _theFarmGameMint,
    address _randomizer
  ) external onlyController {
    eggShop = IEggShop(_eggShop);
    eggToken = IEGGToken(_eggToken);
    farmAnimalsNFT = IFarmAnimals(_farmAnimalsNFT);
    henHouseAdvantage = IHenHouseAdvantage(_henHouseAdvantage);
    henHouseCalc = IHenHouseCalc(_henHouseCalc);
    theFarmGameMint = ITheFarmGameMint(_theFarmGameMint);
    randomizer = IRandomizer(_randomizer);
  }

  /**
   * @notice Set the henHouseAdvantage contract address.
   * @dev Only callable by an existing controller
   */
  function setHenHouseAdvantage(address _henHouseAdvantage) external onlyController {
    henHouseAdvantage = IHenHouseAdvantage(_henHouseAdvantage);
  }

  /**
   * @notice Set the theFarmGameMint contract address.
   * @dev Only callable by an existing controller
   */
  function setTheFarmGameMint(address _theFarmGameMint) external onlyController {
    theFarmGameMint = ITheFarmGameMint(_theFarmGameMint);
  }

  /**
   * @notice Set new golden egg type id of EggShop.
   * @dev Only callable by an existing controller
   */

  function setGoldenEggId(uint256 typeId) external onlyController {
    goldenEggTypeId = typeId;
  }

  /**
   * @notice Set drop rate to calculate dropped amount when coyote drop
   * @dev Only callable by an existing controller
   */

  function setCoyoteDropRate(uint256 _dropCoyoteRate) external onlyController {
    dropCoyoteRate = _dropCoyoteRate;
  }

  /**
   * @notice Set coyote tax percent of the rooster's claimed $EGG by rate when unstake
   * @dev Only callable by an existing controller
   */

  function setRoosterClaimTaxPercent(uint256 _taxPercent) external onlyController {
    ROOSTER_MUG_RATE = _taxPercent;
  }

  /**
   * @notice Set new rate to separate the amount of tokens coming from EggToken Contract for GenericEggPool
   * @dev Only callable by an existing controller
   */

  function setGenericEggPoolRate(uint256 _rate) external onlyController {
    genericEggPoolRate = _rate;
  }

  /**
   * @notice Set new rate to separate the amount of tokens coming from EggToken Contract for RescuedEggPool
   * @dev Only callable by an existing controller
   */

  function setRescuedEggPoolRate(uint256 _rate) external onlyController {
    rescuedEggPoolRate = _rate;
  }

  /**
   * @notice Set new golden reward rate
   * @dev Only callable by an existing controller
   */

  function setGoldenRate(uint256 _rate) external onlyController {
    goldenRate = _rate;
  }

  /**
   * @notice Allows owner or conroller to send GenericPool egg to an address (to be used in future seasons)
   * @dev Only callable by an existing controller
   * @param to Address to send all GenericPool token
   */
  function sendGenericPool(address to) external onlyController nonReentrant {
    eggToken.mint(to, genericEggPool);
    genericEggPool = 0;
  }
}
