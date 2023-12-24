// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStakingManagerV1.sol";
import "./Address.sol";
import "./Governable.sol";
import "./Pausable.sol";
import "./IDCounter.sol";
import "./FeeCollector.sol";
import "./IStakingV1.sol";
import "./IStakingFactoryV1.sol";

contract StakingManagerV1 is IStakingManagerV1, Governable, Pausable, IDCounter, FeeCollector {
  using Address for address payable;

  /** @dev set the deployer as both owner and governor initially */
  constructor(address factoryAddress, address feesAddress) Governable(_msgSender(), _msgSender()) {
    _factory = IStakingFactoryV1(factoryAddress);
    _setFeesContract(feesAddress);
  }

  IStakingFactoryV1 internal _factory;

  uint256 internal _gasLeftLimit = 100000;

  mapping(uint40 => IStakingV1) private _staking;
  mapping(address => uint40) private _stakingAddressMap;

  function gasLeftLimit() external view override returns (uint256) {
    return _gasLeftLimit;
  }

  function setGasLeftLimit(uint256 value) external virtual override onlyOwner {
    _gasLeftLimit = value;
  }

  function factory() external view override returns (address) {
    return address(_factory);
  }

  function setFactory(address value) external virtual override onlyOwner {
    _factory = IStakingFactoryV1(value);
  }

  /**
   * @param stakingType_ 0 = eth reflection, 1 = token reflection
   * @param tokenAddress_ address of the staked token
   * @param lockDurationDays_ amount of time in days to restrict withdrawals
   * @param typeData_ additional data specific to stakingType
   */
  function createStaking(
    uint8 stakingType_,
    address tokenAddress_,
    uint16 lockDurationDays_,
    uint256[] memory typeData_
  ) external payable virtual override onlyNotPaused takeFee("DeployStaking") {
    uint40 id = uint40(_next());

    _staking[id] = IStakingV1(
      _factory.createStaking(
        stakingType_,
        tokenAddress_,
        lockDurationDays_,
        typeData_
      )
    );

    address contractAddress = address(_staking[id]);
    _stakingAddressMap[contractAddress] = id;
    emit CreatedStaking(id, contractAddress);
  }

  function _getStakingDataById(uint40 id) internal virtual view returns (
    address contractAddress,
    uint8 stakingType,
    address stakedToken,
    uint8 decimals,
    uint256 totalStaked,
    uint256 totalRewards,
    uint256 totalClaimed
  ){
    (
      stakingType,
      stakedToken,
      decimals,
      totalStaked,
      totalRewards,
      totalClaimed
    ) = _staking[id].getStakingData();

    contractAddress = address(_staking[id]);
  }

  function getStakingDataById(uint40 id) external override view returns (
    address contractAddress,
    uint8 stakingType,
    address stakedToken,
    uint8 decimals,
    uint256 totalStaked,
    uint256 totalRewards,
    uint256 totalClaimed
  ){
    return _getStakingDataById(id);
  }

  function getStakingDataByAddress(address address_) external override view returns (
    address contractAddress,
    uint8 stakingType,
    address stakedToken,
    uint8 decimals,
    uint256 totalStaked,
    uint256 totalRewards,
    uint256 totalClaimed
  ){
    return _getStakingDataById(_stakingAddressMap[address_]);
  }

  function getAllRewardsForAddress(address account) external virtual override view returns (uint256 pending, uint256 claimed) {
    // include total bounty rewards claimed
    // claimed = _bountyRewards[account].claimed;

    for (uint40 i = 0; i < _count && gasleft() > _gasLeftLimit; i++) {
      (,,uint256 amount,uint256 amountClaimed) = _staking[i].getStakingDataForAccount(account);
      pending += amount;
      claimed += amountClaimed;
    }
  }

  function claimAll() external virtual override {
    for (uint40 i = 0; i < _count && gasleft() > _gasLeftLimit; i++) {
      _staking[i].claimFor(_msgSender(), false, false);
    }
  }
}
