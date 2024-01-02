// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Ownable.sol";

///@title AccessControl
/// @notice Handles the different access authorizations for the relayer
abstract contract AccessControl is Ownable {
  /*//////////////////////////////////////////////////////////////
                             STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice exclusive user - when != address(0x0), other users are removed from whitelist
  ///        intended for short term use during incidence response, escrow, migration
  address public exclusiveUser;

  ///@notice guard authorization
  mapping(address => bool) public isGuard;

  ///@notice keeper authorization
  mapping(address => bool) public isKeeper;

  ///@notice user authorization, can use deposit, withdraw
  mapping(address => bool) public isUser;

  ///@notice swapper authorization, can use swap
  mapping(address => bool) public isSwapper;

  ///@notice incentive manager authorization, can set incentives for swaps on Fyde
  mapping(address => bool) public isIncentiveManager;

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event ExclusiveUserSet(address indexed);
  event GuardAdded(address indexed);
  event GuardRemoved(address indexed);
  event KeeperAdded(address indexed);
  event KeeperRemoved(address indexed);
  event UserAdded(address indexed);
  event UserRemoved(address indexed);
  event IncentiveManagerAdded(address indexed);
  event IncentiveManagerRemoved(address indexed);
  event SwapperAdded(address indexed);
  event SwapperRemoved(address indexed);

  /*//////////////////////////////////////////////////////////////
                               SETTER
    //////////////////////////////////////////////////////////////*/

  function setExclusiveUser(address _exclusiveUser) external onlyOwner {
    exclusiveUser = _exclusiveUser;
    emit ExclusiveUserSet(_exclusiveUser);
  }

  function addGuard(address _guard) external onlyOwner {
    isGuard[_guard] = true;
    emit GuardAdded(_guard);
  }

  function removeGuard(address _guard) external onlyOwner {
    isGuard[_guard] = false;
    emit GuardRemoved(_guard);
  }

  function addKeeper(address _keeper) external onlyOwner {
    isKeeper[_keeper] = true;
    emit KeeperAdded(_keeper);
  }

  function removeKeeper(address _keeper) external onlyOwner {
    isKeeper[_keeper] = false;
    emit KeeperRemoved(_keeper);
  }

  function addUser(address[] calldata _user) external onlyOwner {
    for (uint256 i; i < _user.length; ++i) {
      isUser[_user[i]] = true;
      emit UserAdded(_user[i]);
    }
  }

  function removeUser(address[] calldata _user) external onlyOwner {
    for (uint256 i; i < _user.length; ++i) {
      isUser[_user[i]] = false;
      emit UserRemoved(_user[i]);
    }
  }

  function addIncentiveManager(address _incentiveManager) external onlyOwner {
    isIncentiveManager[_incentiveManager] = true;
    emit IncentiveManagerAdded(_incentiveManager);
  }

  function removeIncentiveManager(address _incentiveManager) external onlyOwner {
    isIncentiveManager[_incentiveManager] = false;
    emit IncentiveManagerRemoved(_incentiveManager);
  }

  function addSwapper(address _swapper) external onlyOwner {
    isSwapper[_swapper] = true;
    emit SwapperAdded(_swapper);
  }

  function removeSwapper(address _swapper) external onlyOwner {
    isSwapper[_swapper] = false;
    emit SwapperRemoved(_swapper);
  }

  /*//////////////////////////////////////////////////////////////
                               MODIFIER
    //////////////////////////////////////////////////////////////*/

  ///@notice only a registered keeper can access
  modifier onlyKeeper() {
    if (!isKeeper[msg.sender]) revert Unauthorized();
    _;
  }

  ///@notice only a registered guard can access
  modifier onlyGuard() {
    if (!isGuard[msg.sender]) revert Unauthorized();
    _;
  }

  ///@dev whitelisting address(0x0) disables whitelist -> full permissionless access
  ///@dev setting exclusiveUser to != address(0x0) blocks everyone else
  ///     - intended for escrow, incidence response and migration
  modifier onlyUser() {
    // if whitelist is not disabeld and user not whitelisted -> no access
    if (!isUser[address(0x0)] && !isUser[msg.sender]) revert Unauthorized();
    // if exclusive user exists and is not user -> no accesss
    if (exclusiveUser != address(0x0) && exclusiveUser != msg.sender) revert Unauthorized();
    _;
  }

  ///@dev whitelisting address(0x0) disables whitelist -> full permissionless access
  ///@dev setting exclusiveUser to != address(0x0) blocks everyone else
  ///     - intended for escrow, incidence response and migration
  modifier onlySwapper() {
    if (!isSwapper[address(0x0)] && !isSwapper[msg.sender]) revert Unauthorized();
    if (exclusiveUser != address(0x0) && exclusiveUser != msg.sender) revert Unauthorized();
    _;
  }
}
