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
import "./ReentrancyGuard.sol";
import "./IHenHouseAdvantage.sol";

contract HenHouseAdvantage is IHenHouseAdvantage, ReentrancyGuard {
  // Events
  event InitializedContract(address thisContract);
  event AdvantageBonusAdded(uint256 indexed tokenId, uint256 bonusPercentage, uint256 bonusDurationMins);
  event AdvantageBonusRemoved(uint256 indexed tokenId);

  // Interfaces

  mapping(address => bool) private controllers; // address => allowedToCallFunctions

  mapping(uint256 => AdvantageBonus) public productions; // map token Id to ProductionBonus

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

  constructor() {
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

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /** READ ONLY */

  /**
   * @notice Return the advantage of a tokenId
   * @param tokenId the tokenId to view production bonus
   */
  function getAdvantageBonus(uint256 tokenId) external view returns (AdvantageBonus memory) {
    AdvantageBonus memory advantageBonus = productions[tokenId];
    return advantageBonus;
  }

  /** ACCOUNTING */

  /**
   * @notice Calculate $EGG advantage bonus amount of Staked NFT
   * @param tokenId the ID of the NFT to calculate $EGG advantage bonus amount
   * @return owed - the advantage $EGG bonus amount
   */

  function calculateAdvantageBonus(uint256 tokenId, uint256 owed) external view returns (uint256) {
    AdvantageBonus memory advantage = productions[tokenId];
    if (advantage.startTime > 0 && advantage.bonusDurationMins > 0 && advantage.bonusPercentage > 0) {
      uint256 bonusTime = block.timestamp - advantage.startTime;
      if (bonusTime <= advantage.bonusDurationMins) {
        owed = owed + (owed * (advantage.bonusPercentage)) / 10**4;
      } else {
        // calculate the percentage of the duration time in bonus time
        uint256 lastBonusPercent = (advantage.bonusDurationMins * 100) / bonusTime;
        owed = owed + ((owed * advantage.bonusPercentage) / 10**4) * (lastBonusPercent / 100);
      }
      return owed;
    } else {
      return owed;
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
   * @notice add the advantage of bonus for the tokenId to advantage struct
   * @dev Only callable by an existing controller
   * @param tokenId the tokenId to add production bonus
   * @param _durationMins the minutes number for the period of production bonus
   * @param _percentage the percent for add production bonus
   */
  function addAdvantageBonus(
    uint256 tokenId,
    uint256 _durationMins,
    uint256 _percentage
  ) external override onlyController {
    productions[tokenId] = AdvantageBonus({
      tokenId: tokenId,
      bonusPercentage: _percentage,
      bonusDurationMins: _durationMins * 1 minutes,
      startTime: 0
    });
    emit AdvantageBonusAdded(tokenId, _percentage, _durationMins * 1 minutes);
  }

  /**
   * @notice remove the advantage of bonus for the tokenId from advantage struct
   * @dev Only callable by an existing controller
   * @param tokenId the tokenId to remove production bonus
   */
  function removeAdvantageBonus(uint256 tokenId) public onlyController {
    AdvantageBonus memory advantageBonus = productions[tokenId];
    if (advantageBonus.tokenId > 0) {
      delete productions[tokenId];
      emit AdvantageBonusRemoved(tokenId);
    }
  }

  /**
   * @notice updates the advantage calcs for a token id
   * @dev Only callable by an existing controller
   * @param tokenId array of the address to enable
   */
  function updateAdvantageBonus(uint256 tokenId) external onlyController {
    AdvantageBonus memory advantage = productions[tokenId];
    if (advantage.startTime > 0 && advantage.bonusDurationMins > 0 && advantage.bonusPercentage > 0) {
      uint256 bonusTime = block.timestamp - advantage.startTime;

      if (bonusTime <= advantage.bonusDurationMins) {
        productions[tokenId] = AdvantageBonus({
          tokenId: tokenId,
          bonusPercentage: advantage.bonusPercentage,
          bonusDurationMins: advantage.bonusDurationMins - bonusTime,
          startTime: block.timestamp
        });
      } else {
        removeAdvantageBonus(tokenId);
      }
    } else if (advantage.startTime == 0 && advantage.bonusDurationMins > 0 && advantage.bonusPercentage > 0) {
      productions[tokenId] = AdvantageBonus({
        tokenId: tokenId,
        bonusPercentage: advantage.bonusPercentage,
        bonusDurationMins: advantage.bonusDurationMins,
        startTime: block.timestamp
      });
    }
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
}
