//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

//import "./console.sol";
import "./SafeMath.sol";

contract Test {
  using SafeMath for uint256;

  event MigratedToNodePack(address indexed entity, uint128 fromNodeId, uint toPackId, uint nodeSeconds, uint totalSeconds);
  event Created(address indexed entity, uint packType, uint nodesCount, bool usedCredit, uint timestamp, address migratedFrom, uint lastPaidAt);

  uint constant public secondsPerBlock = 13;

  mapping(address => uint128) public entityNodeCount;
  mapping(bytes => uint256) public entityNodePaidOnBlock;
  mapping(bytes => uint256) public entityNodeClaimedTotal;

  function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
    uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
    return abi.encodePacked(entity, id);
  }

  function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
    return 0;
//    uint256 rewardsAll = 0;
//
//    for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
//      rewardsAll = rewardsAll.add(getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number));
//    }
//
//    return rewardsAll;
  }

  function setup() external {
    entityNodeCount[msg.sender] = 5;
    entityNodePaidOnBlock[getNodeId(msg.sender, 1)] = 14848087;
    entityNodePaidOnBlock[getNodeId(msg.sender, 2)] = 14945039;
    entityNodePaidOnBlock[getNodeId(msg.sender, 3)] = 14851391;
    entityNodePaidOnBlock[getNodeId(msg.sender, 4)] = 14982358;
    entityNodePaidOnBlock[getNodeId(msg.sender, 5)] = 14936284;
  }

  function migrateAll() external payable {
//    uint256 blockNumber = 14969712;
//    uint256 blockTimestamp = 1655328937;
//    uint256 blockNumber = block.number;
//    uint256 blockTimestamp = block.timestamp;

    uint256 totalClaimed = 0;
    uint128 migratedNodes = 0;
    uint256 totalSeconds = 0;
    uint256 rewardsDue = getRewardAll(msg.sender, 0);

    for (uint128 nodeId = 1; nodeId <= entityNodeCount[msg.sender]; nodeId++) {
      bytes memory id = getNodeId(msg.sender, nodeId);
      bool migrated = true;
      if (migrated) {
        migratedNodes += 1;
        totalClaimed = totalClaimed.add(entityNodeClaimedTotal[id]);
        totalSeconds = totalSeconds.add(block.timestamp - ((block.number - entityNodePaidOnBlock[id]) * secondsPerBlock));
        emit MigratedToNodePack(msg.sender, nodeId, 1, block.timestamp - ((block.number - entityNodePaidOnBlock[id]) * secondsPerBlock), totalSeconds);
      }
    }

//    console.log("block.number: ", block.number);
//    console.log("block.timestamp: ", block.timestamp);
//    console.log("totalSeconds: ", totalSeconds);
//    console.log("totalSeconds / migratedNodes: ", totalSeconds / migratedNodes);
//    console.log("totalSeconds.div(migratedNodes): ", totalSeconds.div(migratedNodes));

    require(migratedNodes > 0, "nothing to migrate");

//    entityNodeDeactivatedCount[msg.sender] += migratedNodes;
    migrateNodes(msg.sender, 1, migratedNodes, totalSeconds / migratedNodes, rewardsDue, totalClaimed);
  }

  function migrateNodes(address _entity, uint _packType, uint _nodeCount, uint _lastPaidAt, uint _rewardsDue, uint _totalClaimed) public returns (bool) {
    emit Created(_entity, _packType, _nodeCount, false, block.timestamp, msg.sender, _lastPaidAt);

    return true;
  }
}
