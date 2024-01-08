// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./IERC1155Preset.sol";
import "./StrongPoolInterface.sol";
import "./AdminAccessControl.sol";
import "./StrongNFTBonusInterface.sol";
import "./rewards.sol";

contract NodesV2 is AdminAccessControl {

  event Requested(address indexed miner);
  event Claimed(address indexed miner, uint256 reward);
  event Paid(address indexed entity, uint128 nodeId, bool isRenewal, uint256 upToBlockNumber);

  using SafeMath for uint256;

  IERC20 public strongToken;
  StrongPoolInterface public strongPool;

  bool public initDone;
  uint256 public activeEntities;
  address payable public feeCollector;
  uint256 public rewardPerBlockNumerator;
  uint256 public rewardPerBlockDenominator;
  uint256 public rewardPerBlockNumeratorNew;
  uint256 public rewardPerBlockDenominatorNew;
  uint256 public rewardPerBlockNewEffectiveBlock;
  uint256 public claimingFeeNumerator;
  uint256 public claimingFeeDenominator;
  uint256 public requestingFeeInWei;
  uint256 public strongFeeInWei;
  uint256 public recurringFeeInWei;
  uint256 public recurringPaymentCycleInBlocks;
  uint256 public rewardBalance;
  uint256 public claimingFeeInWei;
  uint256 public gracePeriodInBlocks;
  uint128 public maxNodes;
  uint256 public maxPaymentPeriods;
  mapping(bytes => uint256) public entityNodePaidOnBlock;
  mapping(bytes => uint256) public entityNodeClaimedOnBlock;
  mapping(address => uint128) public entityNodeCount;

  StrongNFTBonusInterface public strongNFTBonus;

  function init(
    address _strongTokenAddress,
    address _strongPoolAddress,
    uint256 _rewardPerBlockNumeratorValue,
    uint256 _rewardPerBlockDenominatorValue,
    uint256 _requestingFeeInWeiValue,
    uint256 _strongFeeInWeiValue,
    uint256 _recurringFeeInWeiValue,
    uint256 _recurringPaymentCycleInBlocksValue,
    uint256 _claimingFeeNumeratorValue,
    uint256 _claimingFeeDenominatorValue
  ) public {
    require(!initDone, "init done");

    strongToken = IERC20(_strongTokenAddress);
    strongPool = StrongPoolInterface(_strongPoolAddress);
    rewardPerBlockNumerator = _rewardPerBlockNumeratorValue;
    rewardPerBlockDenominator = _rewardPerBlockDenominatorValue;
    requestingFeeInWei = _requestingFeeInWeiValue;
    strongFeeInWei = _strongFeeInWeiValue;
    recurringFeeInWei = _recurringFeeInWeiValue;
    claimingFeeNumerator = _claimingFeeNumeratorValue;
    claimingFeeDenominator = _claimingFeeDenominatorValue;
    recurringPaymentCycleInBlocks = _recurringPaymentCycleInBlocksValue;
    maxNodes = 100;
    initDone = true;
  }

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function canBePaid(address _entity, uint128 _nodeId) public view returns (bool) {
    return !hasNodeExpired(_entity, _nodeId) && !hasMaxPayments(_entity, _nodeId);
  }

  function doesNodeExist(address _entity, uint128 _nodeId) public view returns (bool) {
    return entityNodePaidOnBlock[getNodeId(_entity, _nodeId)] > 0;
  }

  function hasNodeExpired(address _entity, uint128 _nodeId) public view returns (bool) {
    uint256 blockLastPaidOn = entityNodePaidOnBlock[getNodeId(_entity, _nodeId)];
    return block.number > blockLastPaidOn.add(recurringPaymentCycleInBlocks).add(gracePeriodInBlocks);
  }

  function hasMaxPayments(address _entity, uint128 _nodeId) public view returns (bool) {
    uint256 blockLastPaidOn = entityNodePaidOnBlock[getNodeId(_entity, _nodeId)];
    uint256 limit = block.number.add(recurringPaymentCycleInBlocks.mul(maxPaymentPeriods));

    return blockLastPaidOn.add(recurringPaymentCycleInBlocks) >= limit;
  }

  function getNodeId(address _entity, uint128 _nodeId) public view returns (bytes memory) {
    uint128 id = _nodeId != 0 ? _nodeId : entityNodeCount[_entity] + 1;
    return abi.encodePacked(_entity, id);
  }

  function getNodePaidOn(address _entity, uint128 _nodeId) public view returns (uint256) {
    return entityNodePaidOnBlock[getNodeId(_entity, _nodeId)];
  }

  function getReward(address _entity, uint128 _nodeId) public view returns (uint256) {
    return getRewardByBlock(_entity, _nodeId, block.number);
  }

  function getRewardAll(address _entity, uint256 _blockNumber) public view returns (uint256) {
    uint256 rewardsAll = 0;

    for (uint128 i = 1; i <= entityNodeCount[_entity]; i++) {
      rewardsAll = rewardsAll.add(getRewardByBlock(_entity, i, _blockNumber > 0 ? _blockNumber : block.number));
    }

    return rewardsAll;
  }

  function getRewardByBlock(address _entity, uint128 _nodeId, uint256 _blockNumber) public view returns (uint256) {
    bytes memory id = getNodeId(_entity, _nodeId);

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];

    if (_blockNumber > block.number) return 0;
    if (blockLastClaimedOn == 0) return 0;
    if (_blockNumber < blockLastClaimedOn) return 0;

    uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, _blockNumber);
    uint256 rewardOld = rewardPerBlockDenominator > 0 ? rewardBlocks[0].mul(rewardPerBlockNumerator).div(rewardPerBlockDenominator) : 0;
    uint256 rewardNew = rewardPerBlockDenominatorNew > 0 ? rewardBlocks[1].mul(rewardPerBlockNumeratorNew).div(rewardPerBlockDenominatorNew) : 0;

    uint256 bonus = address(strongNFTBonus) != address(0)
    ? strongNFTBonus.getBonus(_entity, _nodeId, blockLastClaimedOn, _blockNumber)
    : 0;

    return rewardOld.add(rewardNew).add(bonus);
  }

  function isEntityActive(address _entity) public view returns (bool) {
    return doesNodeExist(_entity, 1) && !hasNodeExpired(_entity, 1);
  }

  //
  // Actions
  // -------------------------------------------------------------------------------------------------------------------

  function requestAccess() public payable {
    require(entityNodeCount[msg.sender] < maxNodes, "limit reached");
    require(msg.value == requestingFeeInWei, "invalid fee");

    uint128 nodeId = entityNodeCount[msg.sender] + 1;
    bytes memory id = getNodeId(msg.sender, nodeId);

    activeEntities = activeEntities.add(1);

    entityNodePaidOnBlock[id] = block.number;
    entityNodeClaimedOnBlock[id] = block.number;
    entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

    feeCollector.transfer(msg.value);
    strongToken.transferFrom(msg.sender, feeCollector, strongFeeInWei);

    emit Paid(msg.sender, nodeId, false, entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks));
  }

  function payFee(uint128 _nodeId) public payable {
    address sender = msg.sender == address(this) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, _nodeId);

    require(doesNodeExist(sender, _nodeId), "doesnt exist");
    require(hasNodeExpired(sender, _nodeId) == false, "too late");
    require(hasMaxPayments(sender, _nodeId) == false, "too soon");
    require(msg.value == recurringFeeInWei, "invalid fee");

    feeCollector.transfer(msg.value);
    entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

    emit Paid(sender, _nodeId, true, entityNodePaidOnBlock[id]);
  }

  function claim(uint128 _nodeId, uint256 _blockNumber, bool _toStrongPool) public payable returns (bool) {
    address sender = msg.sender == address(this) || msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, _nodeId);

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

    require(blockLastClaimedOn != 0, "never claimed");
    require(_blockNumber <= block.number, "invalid block");
    require(_blockNumber > blockLastClaimedOn, "too soon");

    if (recurringFeeInWei != 0) {
      require(_blockNumber < blockLastPaidOn.add(recurringPaymentCycleInBlocks), "pay fee");
    }

    uint256 reward = getRewardByBlock(sender, _nodeId, _blockNumber);
    require(reward > 0, "no reward");

    uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
    require(msg.value >= fee, "invalid fee");

    feeCollector.transfer(msg.value);

    if (_toStrongPool) {
      strongToken.approve(address(strongPool), reward);
      strongPool.mineFor(sender, reward);
    } else {
      strongToken.transfer(sender, reward);
    }

    rewardBalance = rewardBalance.sub(reward);
    entityNodeClaimedOnBlock[id] = _blockNumber;
    emit Claimed(sender, reward);

    return true;
  }

  function claimAll(uint256 _blockNumber, bool _toStrongPool) public payable {
    uint256 value = msg.value;
    for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
      uint256 reward = getRewardByBlock(msg.sender, i, _blockNumber);
      uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
      require(value >= fee, "invalid fee");
      require(this.claim{value : fee}(i, _blockNumber, _toStrongPool), "claim failed");
      value = value.sub(fee);
    }
  }

  function payAll(uint256 _nodeCount) public payable {
    require(_nodeCount > 0, "invalid value");
    require(msg.value == recurringFeeInWei.mul(_nodeCount), "invalid fee");

    for (uint16 nodeId = 1; nodeId <= entityNodeCount[msg.sender]; nodeId++) {
      if (!canBePaid(msg.sender, nodeId)) {
        continue;
      }

      this.payFee{value : recurringFeeInWei}(nodeId);
      _nodeCount = _nodeCount.sub(1);
    }

    require(_nodeCount == 0, "invalid count");
  }

  //
  // Admin
  // -------------------------------------------------------------------------------------------------------------------

  function deposit(uint256 _amount) public onlyRole(adminControl.SUPER_ADMIN()) {
    require(_amount > 0);
    strongToken.transferFrom(msg.sender, address(this), _amount);
    rewardBalance = rewardBalance.add(_amount);
  }

  function withdraw(address _destination, uint256 _amount) public onlyRole(adminControl.SUPER_ADMIN()) {
    require(_amount > 0);
    require(rewardBalance >= _amount, "not enough");
    strongToken.transfer(_destination, _amount);
    rewardBalance = rewardBalance.sub(_amount);
  }

  function updateFeeCollector(address payable _newFeeCollector) public onlyRole(adminControl.SUPER_ADMIN()) {
    require(_newFeeCollector != address(0));
    feeCollector = _newFeeCollector;
  }

  function updateRequestingFee(uint256 _feeInWei) public onlyRole(adminControl.SERVICE_ADMIN()) {
    requestingFeeInWei = _feeInWei;
  }

  function updateStrongFee(uint256 _feeInWei) public onlyRole(adminControl.SERVICE_ADMIN()) {
    strongFeeInWei = _feeInWei;
  }

  function updateClaimingFee(uint256 _numerator, uint256 _denominator) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_denominator != 0);
    claimingFeeNumerator = _numerator;
    claimingFeeDenominator = _denominator;
  }

  function updateRecurringFee(uint256 _feeInWei) public onlyRole(adminControl.SERVICE_ADMIN()) {
    recurringFeeInWei = _feeInWei;
  }

  function updateRecurringPaymentCycleInBlocks(uint256 _blocks) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_blocks > 0);
    recurringPaymentCycleInBlocks = _blocks;
  }

  function updateGracePeriodInBlocks(uint256 _blocks) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_blocks > 0);
    gracePeriodInBlocks = _blocks;
  }

  function updateLimits(uint128 _maxNodes, uint256 _maxPaymentPeriods) public onlyRole(adminControl.SERVICE_ADMIN()) {
    maxNodes = _maxNodes;
    maxPaymentPeriods = _maxPaymentPeriods;
  }

  function updateRewardPerBlock(uint256 _numerator, uint256 _denominator) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_denominator != 0);
    rewardPerBlockNumerator = _numerator;
    rewardPerBlockDenominator = _denominator;
  }

  function updateRewardPerBlockNew(uint256 _numerator, uint256 _denominator, uint256 _effectiveBlock) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_denominator != 0);
    rewardPerBlockNumeratorNew = _numerator;
    rewardPerBlockDenominatorNew = _denominator;
    rewardPerBlockNewEffectiveBlock = _effectiveBlock != 0 ? _effectiveBlock : block.number;
  }

  function addNFTBonusContract(address _contract) public onlyRole(adminControl.SERVICE_ADMIN()) {
    strongNFTBonus = StrongNFTBonusInterface(_contract);
  }
}
