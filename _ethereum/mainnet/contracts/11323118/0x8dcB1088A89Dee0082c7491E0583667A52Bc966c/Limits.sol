// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./PuulAccessControl.sol";
import "./Console.sol";

contract Limits is PuulAccessControl, ReentrancyGuard {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct LimitValues {
    uint256 minPuul;
    uint256 minPuulStake;
    uint256 minDeposit;
    uint256 maxDeposit;
    uint256 maxTotal;
  }

  address _puul;
  address _puulStake;
  mapping (address => LimitValues) _limits;

  constructor (address puul, address puulStake) public {
    _puul = puul;
    _puulStake = puulStake;
    _setupRole(ROLE_ADMIN, msg.sender);
    _setupRole(ROLE_HARVESTER, msg.sender);
  }

  function setupRoles(address defaultAdmin, address admin, address harvester) onlyDefaultAdmin external {
    _setupRoles(defaultAdmin, admin, harvester);
  }

  function _setupRoles(address defaultAdmin, address admin, address harvester) internal {
    _setup(ROLE_ADMIN, admin);
    _setup(ROLE_HARVESTER, harvester);
    _setupAdmin(admin);
    _setupDefaultAdmin(defaultAdmin);
  }

  function setMinPuul(address pool, uint256 value) onlyHarvester external {
    _limits[pool].minPuul = value;
  }

  function setMinPuulStake(address pool, uint256 value) onlyHarvester external {
    _limits[pool].minPuulStake = value;
  }

  function setMinDeposit(address pool, uint256 value) onlyHarvester external {
    _limits[pool].minDeposit = value;
  }

  function setMaxDeposit(address pool, uint256 value) onlyHarvester external {
    _limits[pool].maxDeposit = value;
  }

  function setMaxTotal(address pool, uint256 value) onlyHarvester external {
    _limits[pool].maxTotal = value;
  }

  function checkLimits(address sender, address pool, uint256 amount) external view {
    uint256 minPuul = _limits[pool].minPuul;
    if (minPuul > 0)
      require(IERC20(_puul).balanceOf(sender) >= minPuul, '!minPuul');
    uint256 minPuulStake = _limits[pool].minPuulStake;
    if (minPuulStake > 0)
      require(IERC20(_puulStake).balanceOf(sender) >= minPuulStake, '!minPuulStake');
    uint256 minDeposit = _limits[pool].minDeposit;
    if (minDeposit > 0)
      require(amount >= minDeposit, '!minDeposit');
    uint256 maxDeposit = _limits[pool].maxDeposit;
    if (maxDeposit > 0)
      require(amount <= maxDeposit, '!maxDeposit');
    uint256 maxTotal = _limits[pool].maxTotal;
    if (maxTotal > 0)
      require(amount.add(IERC20(pool).totalSupply()) <= maxTotal, '!maxTotal');
  }

  function getMinPuul(address pool) view external returns(uint256) {
    return _limits[pool].minPuul;
  }

  function getMinPuulStake(address pool) view external returns(uint256) {
    return _limits[pool].minPuulStake;
  }

  function getMinDeposit(address pool) view external returns(uint256) {
    return _limits[pool].minDeposit;
  }

  function getMaxDeposit(address pool) view external returns(uint256) {
    return _limits[pool].maxDeposit;
  }

  function getMaxTotal(address pool) view external returns(uint256) {
    return _limits[pool].maxTotal;
  }

}
