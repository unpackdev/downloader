// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

import "./SRC20.sol";

/**
 * @dev SRC20 registry contains the address of every created
 * SRC20 token. Registered factories can add addresses of
 * new tokens, public can query tokens.
 */
contract SRC20Registry is Ownable {
  using SafeMath for uint256;

  struct SRC20Record {
    address minter;
    bool isRegistered;
  }

  address public treasury;
  address public rewardPool;

  mapping(address => mapping(address => bool)) public fundraise;
  mapping(address => bool) public authorizedMinters;
  mapping(address => bool) public authorizedFactories;
  mapping(address => SRC20Record) public registry;

  event Deployed(address treasury, address rewardPool);
  event TreasuryUpdated(address treasury);
  event RewardPoolUpdated(address rewardPool);
  event SRC20Registered(address token, address minter);
  event SRC20Unregistered(address token);
  event MinterAdded(address minter);
  event MinterRemoved(address minter);
  event FundraiserRegistered(address fundraiser, address registrant, address token);

  constructor(address _treasury, address _rewardPool) {
    require(_treasury != address(0), 'SRC20Registry: Treasury must be set');
    require(_rewardPool != address(0), 'SRC20Registry: Reward pool must be set');
    treasury = _treasury;
    rewardPool = _rewardPool;
    emit Deployed(treasury, rewardPool);
  }

  function updateTreasury(address _treasury) external onlyOwner returns (bool) {
    require(_treasury != address(0), 'SRC20Registry: Treasury cannot be the zero address');
    treasury = _treasury;
    emit TreasuryUpdated(_treasury);
    return true;
  }

  function updateRewardPool(address _rewardPool) external onlyOwner returns (bool) {
    require(_rewardPool != address(0), 'SRC20Registry: Reward pool cannot be the zero address');
    rewardPool = _rewardPool;
    emit RewardPoolUpdated(_rewardPool);
    return true;
  }

  function registerFundraise(address _registrant, address _token) external returns (bool) {
    require(_registrant == SRC20(_token).owner(), 'SRC20Registry: Registrant not token owner');
    require(registry[_token].isRegistered, 'SRC20Registry: Token not in registry');
    require(
      fundraise[_token][msg.sender] == false,
      'SRC20Registry: Fundraiser already in registry'
    );

    fundraise[_token][msg.sender] = true;
    emit FundraiserRegistered(msg.sender, _registrant, _token);

    return true;
  }

  function register(address _token, address _minter) external returns (bool) {
    require(_token != address(0), 'SRC20Registry: Token is zero address');
    require(authorizedMinters[_minter], 'SRC20Registry: Minter not authorized');
    require(registry[_token].isRegistered == false, 'SRC20Registry: Token already in registry');

    registry[_token].minter = _minter;
    registry[_token].isRegistered = true;

    emit SRC20Registered(_token, _minter);

    return true;
  }

  function unregister(address _token) external onlyOwner returns (bool) {
    require(_token != address(0), 'SRC20Registry: Token is zero address');
    require(registry[_token].isRegistered, 'SRC20Registry: Token not in registry');

    registry[_token].minter = address(0);
    registry[_token].isRegistered = false;

    emit SRC20Unregistered(_token);

    return true;
  }

  function contains(address _token) external view returns (bool) {
    return registry[_token].minter != address(0);
  }

  function getMinter(address _token) external view returns (address) {
    return registry[_token].minter;
  }

  function addMinter(address _minter) external onlyOwner returns (bool) {
    require(_minter != address(0), 'SRC20Registry: Minter is zero address');
    require(authorizedMinters[_minter] == false, 'SRC20Registry: Minter is already authorized');

    authorizedMinters[_minter] = true;

    emit MinterAdded(_minter);

    return true;
  }

  function removeMinter(address _minter) external onlyOwner returns (bool) {
    require(_minter != address(0), 'SRC20Registry: Minter is zero address');
    require(authorizedMinters[_minter], 'SRC20Registry: Minter is not authorized');

    authorizedMinters[_minter] = false;

    emit MinterRemoved(_minter);

    return true;
  }
}
