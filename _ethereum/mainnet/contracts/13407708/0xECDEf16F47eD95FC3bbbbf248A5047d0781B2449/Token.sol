// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
/**


     *****   **    **           **              * ***              *****  *       * ***
  ******  ***** *****        *****            *  ****  *        ******  *       *  ****  *
 **   *  *  ***** *****     *  ***           *  *  ****        **   *  *       *  *  ****
*    *  *   * **  * **         ***          *  **   **        *    *  *       *  **   **
    *  *    *     *           *  **        *  ***                 *  *       *  ***
   ** **    *     *           *  **       **   **                ** **      **   **
   ** **    *     *          *    **      **   **   ***          ** **      **   **
   ** **    *     *          *    **      **   **  ****  *     **** **      **   **
   ** **    *     *         *      **     **   ** *  ****     * *** **      **   **
   ** **    *     **        *********     **   ***    **         ** **      **   **
   *  **    *     **       *        **     **  **     *     **   ** **       **  **
      *     *      **      *        **      ** *      *    ***   *  *         ** *      *
  ****      *      **     *****      **      ***     *      ***    *           ***     *
 *  *****           **   *   ****    ** *     *******        ******             *******
*     **                *     **      **        ***            ***                ***
*                       *
 **                      **
                If it is magic you want, then look no further.
                  You should not abscond, but hold with fervor.


                      To be used in the SSS universe.
                    This is not a financial instrument.
*/

interface ISss {
  function tokensOfOwner(address _owner) external view returns(uint256[] memory);
}

contract Magic is ERC20, Ownable {
  // Friday, October 9, 2026 1:41:20 PM
  uint256 public endDate = 1791553280;
  uint256 public rewardTimeframe = 86400;
  uint256 public rewardRate = 1 ether;

  mapping(uint256 => uint256) internal magicStartDates;
  mapping(uint256 => uint256) internal magicClaimed;
  mapping(address => uint256) internal accountClaimed;

  mapping(address => bool) trustedContracts;

  ISss public sss;
  bool public publicBurnEnabled = false;

  event BurningToggled(bool _enabled);
  event MagicRewarded(address indexed _address, uint256 indexed _amount);
  event MagicClaimed(address indexed _address, uint256 indexed _amount);
  event MagicSpent(address indexed _address, uint256 indexed _amount);

  constructor(address _sssAddress) ERC20("Magic", "MAGIC") {
    sss = ISss(_sssAddress);
    trustedContracts[_sssAddress] = true;
  }

  modifier onlyTrustedContracts()  {
    require(trustedContracts[msg.sender] == true, "You can't be trusted");
    _;
  }

  function abrakadabra(uint256[] calldata tokenIds) external {
    require(msg.sender == address(sss), "Can only be initialized by SSS");
    for(uint256 i = 0; i < tokenIds.length; i++) {
      require(magicStartDates[tokenIds[i]] == 0, "Already initialized");
      magicStartDates[tokenIds[i]] = block.timestamp;
    }
  }

  function spendMagic(address _addy, uint256 _amount) external onlyTrustedContracts {
    require(balanceOf(_addy) >= _amount, "You lack the magic");
    _burn(_addy, _amount);
    emit MagicSpent(_addy, _amount);
  }

  function rewardMagic(address _to, uint256 _amount) external onlyOwner {
    _mint(_to, _amount);
    emit MagicRewarded(_to, _amount);
  }

  function burn(uint256 _amount) external {
    require(publicBurnEnabled, "Patience, young one");
    _burn(msg.sender, _amount);
  }

  function claimMagic() external {
    uint256 totalReward;

    uint256[] memory tokenIds = sss.tokensOfOwner(msg.sender);
    uint256 fromTime = min(block.timestamp, endDate);

    for(uint256 i = 0; i < tokenIds.length; i++) {
      uint256 magicStartDate = magicStartDates[tokenIds[i]];
      uint256 totMagicClaimed = magicClaimed[tokenIds[i]];
      uint256 reward = (((fromTime - magicStartDate) / rewardTimeframe) * rewardRate) - totMagicClaimed;

      magicClaimed[tokenIds[i]] = reward;
      totalReward += reward;
    }

    accountClaimed[msg.sender] += totalReward;
    _mint(msg.sender, totalReward);

    emit MagicClaimed(msg.sender, totalReward);
  }

  function totalPending() external view returns(uint256) {
    uint256 pendingRewards;

    uint256[] memory tokenIds = sss.tokensOfOwner(msg.sender);

    uint256 fromTime = min(block.timestamp, endDate);

    for(uint256 i = 0; i < tokenIds.length; i++) {
      uint256 magicStartDate = magicStartDates[tokenIds[i]];
      uint256 totMagicClaimed = magicClaimed[tokenIds[i]];
      uint256 reward = (((fromTime - magicStartDate) / rewardTimeframe) * rewardRate) - totMagicClaimed;

      pendingRewards += reward;
    }

    return pendingRewards;
  }

  function totalClaimed() external view returns(uint256) {
    return accountClaimed[msg.sender];
  }

  function togglePublicBurning() external onlyOwner {
    publicBurnEnabled = !publicBurnEnabled;
    emit BurningToggled(publicBurnEnabled);
  }

  function addTrustedContract(address _contractAddy) external onlyOwner {
    trustedContracts[_contractAddy] = true;
  }

  function removeTrustedContract(address _contractAddy) external onlyOwner {
    delete trustedContracts[_contractAddy];
  }

  function setRewardRate(uint256 _rate) external onlyOwner {
    rewardRate = _rate;
  }

  function setRewardTimeframe(uint256 _timeFrame) external onlyOwner {
    rewardTimeframe = _timeFrame;
  }

  function setEndDate(uint256 _endDate) external onlyOwner {
    endDate = _endDate;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}
