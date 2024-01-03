// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./PuulAccessControl.sol";
import "./Console.sol";

contract RewardDistributor is PuulAccessControl, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  mapping (address => bool) _farms;

  constructor () public {
    _setupRole(ROLE_ADMIN, msg.sender);
    _setupRole(ROLE_HARVESTER, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setupRoles(address admin, address harvester) onlyDefaultAdmin external {
    _setup(ROLE_HARVESTER, harvester);
    _setupAdmin(admin);
    _setupDefaultAdmin(admin);
  }

  function addFarm(address farm) onlyHarvester external {
    _farms[farm] = true;
  }

  function removeFarm(address farm) onlyHarvester external {
    _farms[farm] = false;
  }

  function sendRewardsToFarm(address farm, address reward, uint256 amount) onlyHarvester external {
    require(_farms[farm], '!farm');
    require(reward != address(0), '!reward');
    uint256 bal = IERC20(reward).balanceOf(address(this));
    require (amount > 0 && amount <= bal, '!amount');
    IERC20(reward).safeTransfer(farm, amount);
  }

}
