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

import "./IEGGToken.sol";
import "./IFarmAnimals.sol";
import "./IHenHouse.sol";
import "./IHenHouseAdvantage.sol";

contract HenHouseCalc {
  // Events
  event InitializedContract(address thisContract);

  // Interfaces
  IEGGToken public eggToken; // ref to the $EGG contract for minting $EGG earnings
  IFarmAnimals public farmAnimalsNFT; // ref to the FarmAnimals NFT contract
  IHenHouseAdvantage public henHouseAdvantage; // ref to HenHouseAdvantage contract
  IHenHouse public henHouse; // ref to Hen House contract

  mapping(address => bool) private controllers; // address => allowedToCallFunctions

  // Hens
  uint256 public constant DAILY_EGG_RATE = 10000 ether; // Hens earn 10000 $EGG per day
  uint256 public constant DAILY_ROOSTER_EGG_RATE = 1000 ether; // Rooster earn 1000 ether per day on guard duty

  // Recource tracking
  uint256 public constant MAXIMUM_GLOBAL_EGG = 2880000000 ether; // there will only ever be (roughly) 2.88 billion $EGG earned through staking

  /** MODIFIERS */

  /**
   * @dev Modifer to require msg.sender to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[msg.sender], 'Only controllers');
  }

  constructor(
    IEGGToken _eggToken,
    IFarmAnimals _farmAnimalsNFT,
    IHenHouseAdvantage _henHouseAdvantage
  ) {
    eggToken = _eggToken;
    farmAnimalsNFT = _farmAnimalsNFT;
    henHouseAdvantage = _henHouseAdvantage;
    controllers[msg.sender] = true;

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

  /** ACCOUNTING */

  /** READ ONLY */

  /**
   * @notice Get token kind (chicken, coyote, rooster)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(uint256 tokenId) internal view returns (IFarmAnimals.Kind) {
    return farmAnimalsNFT.getTokenTraits(tokenId).kind;
  }

  /**
   * @notice Gets the rank score for a Coyote
   * @param tokenId the ID of the Coyote to get the rank score for
   * @return the rank score of the Coyote & Rooster(5-8)
   */
  function _rankForCoyoteRooster(uint256 tokenId) internal view returns (uint8) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return uint8(s.advantage + 1); // rank index is 0-5
  }

  /**
    @notice Get claim earning amount by tokenId
    @param tokenId the ID of the token to claim earnings from
   */
  function _calcDailyEggRateOfHen(uint256 tokenId) internal view returns (uint256) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return (s.advantage * 1000 ether + DAILY_EGG_RATE);
  }

  /**
    @notice Get claim earning amount by tokenId
    @param tokenId the ID of the token to claim earnings from
   */
  function _calcDailyEggRateOfRooster(uint256 tokenId) internal view returns (uint256) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return (s.advantage * 100 ether + DAILY_ROOSTER_EGG_RATE);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsHen(uint256 tokenId, IHenHouse.Stake memory stake)
    external
    view
    onlyController
    returns (uint256 owed)
  {
    owed = _calculateRewardsHen(tokenId, stake);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsHen(uint256 tokenId, IHenHouse.Stake memory stake) internal view returns (uint256 owed) {
    /**
     * Hen: Daily yeild
     * Hen: Advantage applied to yeild
     * Hen: Pay Tax
     */
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.HenHouseInfo memory henHouseInfo = henHouse.getHenHouseInfo();
    IHenHouse.GuardHouseInfo memory guardHouseInfo = henHouse.getGuardHouseInfo();
    uint256 globalEgg = henHouseInfo.totalEGGEarnedByHen + guardHouseInfo.totalEGGEarnedByRooster;

    if (globalEgg < MAXIMUM_GLOBAL_EGG) {
      owed = ((block.timestamp - stake.stakedTimestamp) * _calcDailyEggRateOfHen(tokenId)) / 1 days;
    } else if (stake.stakedTimestamp > henHouseInfo.lastClaimTimestampByHen) {
      owed = 0; // $EGG production stopped already
    } else {
      owed =
        ((henHouseInfo.lastClaimTimestampByHen - stake.stakedTimestamp) * _calcDailyEggRateOfHen(tokenId)) /
        1 days; // stop earning additional $EGG if it's all been earned
    }
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsCoyote(uint256 tokenId, uint8 rank) external view onlyController returns (uint256 owed) {
    owed = _calculateRewardsCoyote(tokenId, rank);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Coyote by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Coyote to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsCoyote(uint256 tokenId, uint8 rank) internal view returns (uint256 owed) {
    /**
     * Coyote: Tax yeild
     * Coyote: Advantage applied to yeild
     */

    IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.DenInfo memory denInfo = henHouse.getDenInfo();
    owed = (rank) * (denInfo.eggPerCoyoteRank - stake.eggPerRank); // Calculate portion of tokens based on Rank
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsRooster(
    uint256 tokenId,
    uint8 rank,
    IHenHouse.Stake memory stake
  ) external view onlyController returns (uint256 owed) {
    owed = _calculateRewardsRooster(tokenId, rank, stake);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Rooster by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Rooster to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsRooster(
    uint256 tokenId,
    uint8 rank,
    IHenHouse.Stake memory stake
  ) internal view returns (uint256 owed) {
    /**
     * Rooster: Daily yeild
     * Rooster: Advantage applied to yeild
     * Rooster: One Off Egg
     * Rooster: Rescue Pool
     * Rooster: Risk pay Coyote
     */
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.HenHouseInfo memory henHouseInfo = henHouse.getHenHouseInfo();
    IHenHouse.GuardHouseInfo memory guardHouseInfo = henHouse.getGuardHouseInfo();
    uint256 globalEgg = henHouseInfo.totalEGGEarnedByHen + guardHouseInfo.totalEGGEarnedByRooster;
    owed = (rank) * (guardHouseInfo.eggPerRoosterRank - stake.eggPerRank); // Calculate portion of daily EGG tokens based on Rank

    if (globalEgg < MAXIMUM_GLOBAL_EGG) {
      owed += ((block.timestamp - stake.stakedTimestamp) * (_calcDailyEggRateOfRooster(tokenId))) / 1 days;
    } else if (stake.stakedTimestamp > guardHouseInfo.lastClaimTimestampByRooster) {
      owed += 0; // $EGG production stopped already
    } else {
      owed +=
        ((guardHouseInfo.lastClaimTimestampByRooster - stake.stakedTimestamp) * _calcDailyEggRateOfRooster(tokenId)) /
        1 days; // stop earning additional $EGG if it's all been earned
    }
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
    owed += stake.oneOffEgg;
    owed += (rank) * (guardHouseInfo.rescueEggPerRank - stake.rescueEggPerRank); // Calculate portion of rescued EGG tokens based on Rank
  }

  /**
   * @notice Calculate Reward $EGG token amount of token Id
   * @dev Internal function
   * @param tokenId the ID of the staked NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewards(uint256 tokenId) internal view returns (uint256 owed) {
    IFarmAnimals.Kind kind = _getKind(tokenId);
    if (kind == IFarmAnimals.Kind.HEN) {
      IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
      owed = _calculateRewardsHen(tokenId, stake);
    } else if (kind == IFarmAnimals.Kind.COYOTE) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      owed = _calculateRewardsCoyote(tokenId, rank);
    } else if (kind == IFarmAnimals.Kind.ROOSTER) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
      owed = _calculateRewardsRooster(tokenId, rank, stake);
    }
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
   * @notice Calculate Reward $EGG token amount of token Id
   * @param tokenId the ID of the NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
    owed = _calculateRewards(tokenId);
  }

  /**
   * @notice Calculate Reward $EGG token amount of token Id
   * @param tokenIds Array of the token IDs of the NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateAllRewards(uint256[] calldata tokenIds) external view returns (uint256 owed) {
    uint256 tokenId;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      owed = owed + (_calculateRewards(tokenId));
    }
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
   * @notice Set multiple contract addresses
   * @dev Only callable by an existing controller
   * @param _eggToken Address of eggToken contract
   * @param _farmAnimalsNFT Address of farmAnimals contract
   * @param _henHouseAdvantage Address of henHouseAdvantage contract
   * @param _henHouse Address of henHouse contract
   */

  function setExtContracts(
    address _eggToken,
    address _farmAnimalsNFT,
    address _henHouseAdvantage,
    address _henHouse
  ) external onlyController {
    eggToken = IEGGToken(_eggToken);
    farmAnimalsNFT = IFarmAnimals(_farmAnimalsNFT);
    henHouseAdvantage = IHenHouseAdvantage(_henHouseAdvantage);
    henHouse = IHenHouse(_henHouse);
  }

  /**
   * @notice Set the henHouseAdvantage contract address.
   * @dev Only callable by the owner.
   */
  function setHenHouseAdvantage(address _henHouseAdvantage) external onlyController {
    henHouseAdvantage = IHenHouseAdvantage(_henHouseAdvantage);
  }

  /**
   * @notice Set the henHouse contract address.
   * @dev Only callable by the owner.
   */
  function setHenHouse(address _henHouse) external onlyController {
    henHouse = IHenHouse(_henHouse);
  }
}
