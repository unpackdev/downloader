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

import "./IERC20.sol";
import "./IEggShop.sol";
import "./IEGGToken.sol";
import "./IRandomizer.sol";

contract EggCitement {
  // Events
  event EggCitementReward(address indexed owner, uint256 indexed tokenId, string rewardType);
  event InitializedContract(address thisContract);

  // address => can call allowedToCallFunctions
  mapping(address => bool) private controllers;

  uint256 private eggTokenRewardAmount = 5000 ether;
  uint256 private bonusEGGDuration = 2880; // 48 hours
  uint16 private bonusEGGPercentage = 2500; // 25%

  // Egg shop type IDs
  uint16 private goldenEggTypeId = 4;
  uint16 private platinumEggTypeId = 5;
  uint16 private rainbowEggTypeId = 6;
  uint16 private silverEggTypeId = 7;

  IRandomizer public randomizer; // ref to randomizer
  IEggShop public eggShop; // ref to eggShop collection
  IEGGToken public eggToken; // ref of egg token

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

  /**
   * Instantiates contract
   * Emits InitilizeContracts event to kickstart subgraph
   */

  constructor(
    IEggShop _eggShop,
    IEGGToken _eggToken,
    IRandomizer _randomizer
  ) {
    eggShop = _eggShop;
    eggToken = _eggToken;
    randomizer = _randomizer;

    controllers[msg.sender] = true;

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
   * @notice Give a random reward
   * @param _tokenId The token id to give a reward
   * @param _seed Random seed
   */

  function _reward(uint256 _tokenId, uint256 _seed) internal {
    address recipient = tx.origin;

    uint256 seed = uint256(keccak256(abi.encode(_seed, tx.origin, _tokenId)));

    uint256 rewardChance = 1;
    if (seed > 0) {
      unchecked {
        rewardChance = seed % 100;
      }
    }

    if (rewardChance < 45) {
      eggToken.mint(recipient, eggTokenRewardAmount);

      emit EggCitementReward(recipient, _tokenId, 'egg_token_5k');
    } else if (rewardChance < 60) {
      eggToken.mint(recipient, eggTokenRewardAmount * 2);
      emit EggCitementReward(recipient, _tokenId, 'egg_token_10k');
    } else if (rewardChance < 75) {
      eggShop.mintFree(silverEggTypeId, 1, recipient);
      emit EggCitementReward(recipient, _tokenId, 'silver_egg');
    } else if (rewardChance < 85) {
      eggShop.mintFree(goldenEggTypeId, 1, recipient);
      emit EggCitementReward(recipient, _tokenId, 'gold_egg');
    } else if (rewardChance < 92) {
      eggShop.mintFree(platinumEggTypeId, 1, recipient);
      emit EggCitementReward(recipient, _tokenId, 'platinum_egg');
    } else if (rewardChance < 97) {
      eggShop.mintFree(rainbowEggTypeId, 1, recipient);
      emit EggCitementReward(recipient, _tokenId, 'rainbow_egg');
    } else if (rewardChance < 100) {
      eggToken.mint(recipient, eggTokenRewardAmount * 5);
      emit EggCitementReward(recipient, uint16(_tokenId), 'egg_token_25k');
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
   * @notice Give a random reward
   * @param _tokenId The token id to give a reward
   * @param _seed Random seed
   */

  function giveReward(uint256 _tokenId, uint256 _seed) external onlyController {
    _reward(_tokenId, _seed);
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
   * @param _randomizer Address of randomizer contract
   */

  function setExtContracts(
    address _eggShop,
    address _eggToken,
    address _randomizer
  ) external onlyController {
    eggShop = IEggShop(_eggShop);
    eggToken = IEGGToken(_eggToken);
    randomizer = IRandomizer(_randomizer);
  }
}
