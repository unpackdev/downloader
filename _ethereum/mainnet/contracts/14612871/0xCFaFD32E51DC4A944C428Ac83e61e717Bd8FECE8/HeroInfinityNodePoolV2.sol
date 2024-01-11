// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./MathUtil.sol";
import "./IHeroInfinityNodePool.sol";

contract HeroInfinityNodePoolV2 is Ownable {
  using SafeMath for uint256;
  using MathUtil for uint256;

  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 feeTime;
    uint256 dueTime;
  }

  mapping(address => mapping(uint256 => uint256)) public userFees;
  mapping(address => bool) public migrated;
  mapping(address => uint256) public nodeOwners;
  mapping(address => NodeEntity[]) private _nodesOfUser;

  uint256 public nodePrice = 200000 * 10**18;
  uint256 public initialRewardRate = 0.04 * 10**4; // starting at 4%
  uint256 public rewardReduceRatePerDay = 0.97 * 100;
  uint256 public minRewardRatePerDay = 0.003 * 10**4; // min rate 0.3%
  uint256 public maxNodesPerWallet = 50;
  uint256 public maxNodes = 5000;

  uint256 public initialNodeFee = 10000000000000000;
  uint256 public minNodeFee = 1000000000000000;
  uint256 public feeDeductionRate = 15; // 15% per month
  uint256 public feeDuration = 28 days;
  uint256 public overDuration = 2 days;

  uint256 public totalNodesCreated = 0;

  IERC20 public hriToken = IERC20(0x0C4BA8e27e337C5e8eaC912D836aA8ED09e80e78);
  IHeroInfinityNodePool public oldNodePool =
    IHeroInfinityNodePool(0xFAd5Ef0F347eb7bB89E798B5d026F60aFA3E2bF4);

  constructor() {}

  function upgradeNode() external {
    IHeroInfinityNodePool.NodeEntity[] memory nodes = oldNodePool.getNodes(
      msg.sender
    );

    for (uint256 i = 0; i < nodes.length; i++) {
      address account = msg.sender;
      _nodesOfUser[account].push(
        NodeEntity({
          name: nodes[i].name,
          creationTime: nodes[i].creationTime,
          lastClaimTime: nodes[i].lastClaimTime,
          feeTime: nodes[i].feeTime,
          dueTime: nodes[i].dueTime
        })
      );
      nodeOwners[account]++;
      totalNodesCreated++;
    }

    migrated[msg.sender] = true;
  }

  function createNode(string memory nodeName, uint256 count) external {
    require(count > 0, "Count should be not 0");
    address account = msg.sender;
    uint256 ownerCount = nodeOwners[account];
    require(
      isNameAvailable(account, nodeName),
      "CREATE NODE: Name not available"
    );
    require(ownerCount + count <= maxNodesPerWallet, "Count Limited");
    require(
      ownerCount == 0 ||
        _nodesOfUser[account][ownerCount - 1].creationTime < block.timestamp,
      "Too many requests"
    );
    require(totalNodesCreated + count <= maxNodes, "Exceed max nodes limit");

    uint256 price = nodePrice * count;

    hriToken.transferFrom(account, address(this), price);

    for (uint256 i = 0; i < count; i++) {
      uint256 time = block.timestamp + i;
      _nodesOfUser[account].push(
        NodeEntity({
          name: nodeName,
          creationTime: time,
          lastClaimTime: time,
          feeTime: time + feeDuration,
          dueTime: time + feeDuration + overDuration
        })
      );
      nodeOwners[account]++;
      totalNodesCreated++;
    }
  }

  function isNameAvailable(address account, string memory nodeName)
    internal
    view
    returns (bool)
  {
    NodeEntity[] memory nodes = _nodesOfUser[account];
    for (uint256 i = 0; i < nodes.length; i++) {
      if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
        return false;
      }
    }
    return true;
  }

  function _getNodeWithCreatime(
    NodeEntity[] storage nodes,
    uint256 _creationTime
  ) internal view returns (NodeEntity storage) {
    uint256 numberOfNodes = nodes.length;
    require(numberOfNodes > 0, "CLAIM ERROR: You don't have nodes to claim");
    bool found = false;
    int256 index = binarySearch(nodes, 0, numberOfNodes, _creationTime);
    uint256 validIndex;
    if (index >= 0) {
      found = true;
      validIndex = uint256(index);
    }
    require(found, "NODE SEARCH: No NODE Found with this blocktime");
    return nodes[validIndex];
  }

  function binarySearch(
    NodeEntity[] memory arr,
    uint256 low,
    uint256 high,
    uint256 x
  ) internal view returns (int256) {
    if (high >= low) {
      uint256 mid = (high + low).div(2);
      if (arr[mid].creationTime == x) {
        return int256(mid);
      } else if (arr[mid].creationTime > x) {
        return binarySearch(arr, low, mid - 1, x);
      } else {
        return binarySearch(arr, mid + 1, high, x);
      }
    } else {
      return -1;
    }
  }

  function getRewardsForDay(uint256 passedDays) public view returns (uint256) {
    uint256 rewards = (nodePrice * initialRewardRate) / (10**4);

    for (uint256 i = 0; i < passedDays - 1; i++) {
      rewards = (rewards * rewardReduceRatePerDay) / 100;
    }

    uint256 minRewards = (nodePrice * minRewardRatePerDay) / (10**4);
    return rewards > minRewards ? rewards : minRewards;
  }

  function getNodeReward(NodeEntity memory node)
    internal
    view
    returns (uint256)
  {
    if (block.timestamp > node.dueTime) {
      return 0;
    }

    uint256 passedSeconds = block.timestamp - node.creationTime;
    uint256 passedDays = passedSeconds.divCeil(86400);
    uint256 todayPassedSeconds = passedSeconds % 86400;
    uint256 secondsDiffBetweenLCTAndNow = block.timestamp - node.lastClaimTime;
    todayPassedSeconds = todayPassedSeconds > secondsDiffBetweenLCTAndNow
      ? secondsDiffBetweenLCTAndNow
      : todayPassedSeconds;

    uint256 rewards = 0;
    for (uint256 i = 1; i <= passedDays; i++) {
      if (node.creationTime + 86400 * i > node.lastClaimTime) {
        uint256 passedSecondsAfterClaim = node.creationTime +
          86400 *
          i -
          node.lastClaimTime;

        uint256 dayReward = getRewardsForDay(i);
        if (i == passedDays) {
          rewards += (dayReward * todayPassedSeconds) / 86400;
        } else {
          if (passedSecondsAfterClaim >= 1 days) {
            rewards += dayReward;
          } else {
            rewards += (dayReward * passedSecondsAfterClaim) / 86400;
          }
        }
      }
    }
    return rewards;
  }

  function getFeeAmount(address account, uint256 createTime)
    public
    view
    returns (uint256)
  {
    uint256 lastFee = userFees[account][createTime];
    if (lastFee == 0) {
      return initialNodeFee;
    }

    uint256 estimatedFee = (lastFee * (100 - feeDeductionRate)) / 100;
    return minNodeFee > estimatedFee ? minNodeFee : estimatedFee;
  }

  function getAllFee(address user) public view returns (uint256) {
    NodeEntity[] storage nodes = _nodesOfUser[user];

    uint256 allFee = 0;
    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].dueTime >= block.timestamp) {
        allFee += getFeeAmount(user, nodes[i].creationTime);
      }
    }

    return allFee;
  }

  function payNodeFee(uint256 _creationTime) external payable {
    address user = msg.sender;
    NodeEntity[] storage nodes = _nodesOfUser[user];
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    uint256 nodeFee = getFeeAmount(user, _creationTime);
    require(msg.value >= nodeFee, "Need to pay fee amount");
    require(node.dueTime >= block.timestamp, "Node is disabled");
    node.feeTime = block.timestamp + feeDuration;
    node.dueTime = node.feeTime + overDuration;
    userFees[user][_creationTime] = nodeFee;
  }

  function payAllNodesFee() external payable {
    address user = msg.sender;
    NodeEntity[] storage nodes = _nodesOfUser[user];
    uint256 allFee = getAllFee(user);

    require(msg.value >= allFee, "Need to pay fee amount");
    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].dueTime >= block.timestamp) {
        uint256 nodeFee = getFeeAmount(user, nodes[i].creationTime);
        nodes[i].feeTime = block.timestamp + feeDuration;
        nodes[i].dueTime = nodes[i].feeTime + overDuration;
        userFees[user][nodes[i].creationTime] = nodeFee;
      }
    }
  }

  function claimNodeReward(uint256 _creationTime) external {
    address account = msg.sender;
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 numberOfNodes = nodes.length;
    require(numberOfNodes > 0, "CLAIM ERROR: You don't have nodes to claim");
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    uint256 rewardNode = getNodeReward(node);
    node.lastClaimTime = block.timestamp;
    hriToken.transfer(account, rewardNode);
  }

  function claimAllNodesReward() external {
    address account = msg.sender;
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    uint256 rewardsTotal = 0;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      uint256 nodeReward = getNodeReward(_node);
      rewardsTotal += nodeReward;
      _node.lastClaimTime = block.timestamp;
    }
    hriToken.transfer(account, rewardsTotal);
  }

  function getRewardTotalAmountOf(address account)
    external
    view
    returns (uint256)
  {
    uint256 nodesCount;
    uint256 rewardCount = 0;

    NodeEntity[] storage nodes = _nodesOfUser[account];
    nodesCount = nodes.length;

    for (uint256 i = 0; i < nodesCount; i++) {
      uint256 nodeReward = getNodeReward(nodes[i]);
      rewardCount += nodeReward;
    }

    return rewardCount;
  }

  function getRewardAmountOf(address account, uint256 creationTime)
    external
    view
    returns (uint256)
  {
    require(creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 numberOfNodes = nodes.length;
    require(numberOfNodes > 0, "CLAIM ERROR: You don't have nodes to claim");
    NodeEntity storage node = _getNodeWithCreatime(nodes, creationTime);
    uint256 nodeReward = getNodeReward(node);
    return nodeReward;
  }

  function getNodes(address account)
    external
    view
    returns (NodeEntity[] memory nodes)
  {
    nodes = _nodesOfUser[account];
  }

  function getNodeNumberOf(address account) external view returns (uint256) {
    return nodeOwners[account];
  }

  function withdrawReward(uint256 amount) external onlyOwner {
    hriToken.transfer(msg.sender, amount);
  }

  function withdrawFee(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }

  function setNodePrice(uint256 newNodePrice) external onlyOwner {
    nodePrice = newNodePrice;
  }

  function setInitialRewardRate(uint256 rate) external onlyOwner {
    initialRewardRate = rate;
  }

  function setRewardReduceRatePerDay(uint256 rate) external onlyOwner {
    rewardReduceRatePerDay = rate;
  }

  function setMinRewardRatePerDay(uint256 rate) external onlyOwner {
    minRewardRatePerDay = rate;
  }

  function setInitialNodeFee(uint256 _feeAmount) external onlyOwner {
    initialNodeFee = _feeAmount;
  }

  function setFeeDuration(uint256 _feeDuration) external onlyOwner {
    feeDuration = _feeDuration;
  }

  function setOverDuration(uint256 _overDuration) external onlyOwner {
    overDuration = _overDuration;
  }

  function setMaxNodesPerWallet(uint256 _count) external onlyOwner {
    maxNodesPerWallet = _count;
  }

  function setFeeDeductionRate(uint256 rate) external onlyOwner {
    feeDeductionRate = rate;
  }

  function setMinNodeFee(uint256 fee) external onlyOwner {
    minNodeFee = fee;
  }

  function setMaxNodes(uint256 _count) external onlyOwner {
    maxNodes = _count;
  }

  receive() external payable {}
}
