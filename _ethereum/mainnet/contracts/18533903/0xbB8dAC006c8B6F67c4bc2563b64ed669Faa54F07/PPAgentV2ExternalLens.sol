// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";
import "./PPAgentV2.sol";
import "./PPAgentV2Interfaces.sol";

contract PPAgentV2ExternalLens {
  uint256 public constant VERSION = 2;

  function getJobsLastExecutedAt(address ppAgentV2, bytes32[] calldata jobKeys) external view returns (
    uint256 blockNumber,
    uint256[] memory results
  ) {
    blockNumber = block.number;
    uint256 len = jobKeys.length;
    results = new uint256[](len);

    for (uint256 i = 0; i < len; i++) {
      results[i] = IPPAgentV2Viewer(ppAgentV2).getJobRaw(jobKeys[i]) >> 224;
    }
  }

  struct JobData {
    bytes32 asBytes32;

    address owner;
    address pendingTransfer;
    uint256 jobLevelMinKeeperCvp;
    IPPAgentV2Viewer.Job details;
    bytes preDefinedCalldata;
    IPPAgentV2Viewer.Resolver resolver;
    RandaoJobData randaoData;
  }

  struct RandaoJobData {
    uint256 jobNextKeeperId;
    uint256 jobReservedSlasherId;
    uint256 jobSlashingPossibleAfter;
    uint256 jobCreatedAt;
  }

  function _shouldFetchRandaoData(address ppAgentV2) internal view returns (bool) {
    try IPPAgentV2Viewer(ppAgentV2).getStrategy() returns (string memory strategy) {
      if (keccak256(abi.encode(strategy)) == keccak256(abi.encode("randao"))) {
        return true;
      }
    } catch (bytes memory) {
    }
    return false;
  }

  function getJobs(address ppAgentV2, bytes32[] calldata jobKeys) external view returns (
    uint256 blockNumber,
    JobData[] memory results
  ) {
    results = new JobData[](jobKeys.length);
    bool fetchRandaoData = _shouldFetchRandaoData(ppAgentV2);

    for (uint256 i = 0; i < jobKeys.length; i++) {
      results[i] = _getJobData(ppAgentV2, jobKeys[i], fetchRandaoData);
    }
    blockNumber = block.number;
  }

  function _getJobData(address ppAgentV2, bytes32 jobKey, bool fetchRandaoData)
    internal view returns (JobData memory result) {
    (
      address owner,
      address pendingTransfer,
      uint256 jobLevelMinKeeperCvp,
      IPPAgentV2Viewer.Job memory details,
      bytes memory preDefinedCalldata,
      IPPAgentV2Viewer.Resolver memory resolver
    ) = IPPAgentV2Viewer(ppAgentV2).getJob(jobKey);
    result = JobData({
      asBytes32: bytes32(IPPAgentV2Viewer(ppAgentV2).getJobRaw(jobKey)),
      owner: owner,
      pendingTransfer: pendingTransfer,
      jobLevelMinKeeperCvp: jobLevelMinKeeperCvp,
      details: details,
      preDefinedCalldata: preDefinedCalldata,
      resolver: resolver,
      randaoData: RandaoJobData({
        jobNextKeeperId: 0,
        jobReservedSlasherId: 0,
        jobSlashingPossibleAfter: 0,
        jobCreatedAt: 0
      })
    });

    if (fetchRandaoData) {
      result.randaoData = _getRandaoJobData(ppAgentV2, jobKey);
    }
  }

  function _getRandaoJobData(address ppAgentV2, bytes32 jobKey) internal view returns (RandaoJobData memory) {
    return RandaoJobData({
      jobNextKeeperId: IPPAgentV2RandaoViewer(ppAgentV2).jobNextKeeperId(jobKey),
      jobReservedSlasherId: IPPAgentV2RandaoViewer(ppAgentV2).jobReservedSlasherId(jobKey),
      jobSlashingPossibleAfter: IPPAgentV2RandaoViewer(ppAgentV2).jobSlashingPossibleAfter(jobKey),
      jobCreatedAt: IPPAgentV2RandaoViewer(ppAgentV2).jobCreatedAt(jobKey)
    });
  }


  function getJobsRaw(address ppAgentV2, bytes32[] calldata jobKeys) external view returns (
    uint256 blockNumber,
    uint256[] memory results
  ) {
    blockNumber = block.number;
    uint256 len = jobKeys.length;
    results = new uint256[](len);

    for (uint256 i = 0; i < len; i++) {
      results[i] = IPPAgentV2Viewer(ppAgentV2).getJobRaw(jobKeys[i]);
    }
  }

  function getJobsRawBytes32(address ppAgentV2, bytes32[] calldata jobKeys) external view returns (
    uint256 blockNumber,
    bytes32[] memory results
  ) {
    blockNumber = block.number;
    uint256 len = jobKeys.length;
    results = new bytes32[](len);

    for (uint256 i = 0; i < len; i++) {
      results[i] = bytes32(IPPAgentV2Viewer(ppAgentV2).getJobRaw(jobKeys[i]));
    }
  }

  function getJobBytes32AndNextBlockSlasherId(address ppAgentV2, bytes32 jobKey) external view returns (
    uint256 nextBlockNumber,
    uint256 nextBlockSlasherId,
    bytes32 binJob
  ) {
    nextBlockNumber = block.number + 1;
    nextBlockSlasherId = IPPAgentV2RandaoViewer(ppAgentV2).getSlasherIdByBlock(nextBlockNumber, jobKey);
    binJob = bytes32(IPPAgentV2Viewer(ppAgentV2).getJobRaw(jobKey));
  }

  struct KeeperLightData {
    address admin;
    address worker;
    uint256 currentStake;
    uint256 slashedStake;
    uint256 compensation;
    uint256 pendingWithdrawalAmount;
    uint256 pendingWithdrawalEndAt;
    uint256 workerBalance;
  }

  struct KeeperData {
    address admin;
    address worker;
    bool isActive;
    uint256 currentStake;
    uint256 slashedStake;
    uint256 compensation;
    uint256 pendingWithdrawalAmount;
    uint256 pendingWithdrawalEndAt;
    uint256 workerBalance;
    RandaoKeeperData randaoData;
  }

  struct RandaoKeeperData {
    uint256 keeperActivationCanBeFinalizedAt;
    bytes32[] assignedJobs;
  }

  function getKeepers(address ppAgentV2, uint256[] calldata keeperIds) external view returns (
    uint256 blockNumber,
    KeeperData[] memory results
  ) {
    results = new KeeperData[](keeperIds.length);
    blockNumber = block.number;
    bool fetchRandaoData = _shouldFetchRandaoData(ppAgentV2);

    for (uint256 i = 0; i < keeperIds.length; i++) {
      results[i] = _getKeeperData(ppAgentV2, keeperIds[i], fetchRandaoData);
    }
  }

  function getAllKeepersUpTo(address ppAgentV2, uint256 to) external view returns (
    uint256 blockNumber,
    KeeperData[] memory results
  ) {
    blockNumber = block.number;
    results = _getKeepers(ppAgentV2, 1, to);
  }

  function getAllKeepersFromTo(address ppAgentV2, uint256 from, uint256 to) external view returns (
    uint256 blockNumber,
    KeeperData[] memory results
  ) {
    blockNumber = block.number;
    results = _getKeepers(ppAgentV2, from, to);
  }

  // both from and to are inclusive
  function _getKeepers(address ppAgentV2, uint256 from, uint256 to) private view returns (
    KeeperData[] memory results
  ) {
    require(from < to, "from should be lt to");
    require(from > 0, "from should be gte 1");

    results = new KeeperData[](to - from + 1);

    bool fetchRandaoData = _shouldFetchRandaoData(ppAgentV2);
    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      results[j++] = _getKeeperData(ppAgentV2, i, fetchRandaoData);
    }
  }

  function _getKeeperData(address ppAgentV2, uint256 keeperId, bool fetchRandaoData)
    internal view returns (KeeperData memory) {
    (
      address admin,
      address worker,
      bool isActive,
      uint256 currentStake,
      uint256 slashedStake,
      uint256 compensation,
      uint256 pendingWithdrawalAmount,
      uint256 pendingWithdrawalEndAt
    ) = IPPAgentV2Viewer(ppAgentV2).getKeeper(keeperId);
    return KeeperData({
      admin: admin,
      worker: worker,
      isActive: isActive,
      currentStake: currentStake,
      slashedStake: slashedStake,
      compensation: compensation,
      pendingWithdrawalAmount: pendingWithdrawalAmount,
      pendingWithdrawalEndAt: pendingWithdrawalEndAt,
      workerBalance: worker.balance,
      randaoData: _getRandaoKeeperData(ppAgentV2, keeperId, fetchRandaoData)
    });
  }

  function _getRandaoKeeperData(address ppAgentV2, uint256 keeperId, bool fetchRandaoData)
    internal view returns (RandaoKeeperData memory) {
    if (fetchRandaoData) {
      return RandaoKeeperData({
        keeperActivationCanBeFinalizedAt: IPPAgentV2RandaoViewer(ppAgentV2).keeperActivationCanBeFinalizedAt(keeperId),
        assignedJobs: IPPAgentV2RandaoViewer(ppAgentV2).getJobsAssignedToKeeper(keeperId)
      });
    } else {
      return RandaoKeeperData({
        keeperActivationCanBeFinalizedAt: 0,
        assignedJobs: new bytes32[](0)
      });
    }
  }

  function getOwnerBalances(address ppAgentV2, address[] calldata owners) external view returns (
    uint256 blockNumber,
    uint256[] memory results
  ) {
    blockNumber = block.number;
    uint256 len = owners.length;
    results = new uint256[](len);

    for (uint256 i = 0; i < len; i++) {
      results[i] = IPPAgentV2Viewer(ppAgentV2).jobOwnerCredits(owners[i]);
    }
  }

  struct AgentLightData {
    uint256 latestBlockNumber;
    address cvp;
    address owner;

    // config
    uint256 minKeeperCvp;
    uint256 pendingWithdrawalTimeoutSeconds;
    uint256 feeTotal;
    uint256 feePpm;
    uint256 lastKeeperId;
  }

  function getAgentLightData(address ppAgentV2) external view returns (AgentLightData memory lightData) {
    (
      uint256 minKeeperCvp_,
      uint256 pendingWithdrawalTimeoutSeconds_,
      uint256 feeTotal_,
      uint256 feePpm_,
      uint256 lastKeeperId_
    ) = IPPAgentV2Viewer(ppAgentV2).getConfig();

    lightData = AgentLightData({
      latestBlockNumber: block.number,
      cvp: IPPAgentV2Viewer(ppAgentV2).CVP(),
      owner: Ownable(ppAgentV2).owner(),
      minKeeperCvp: minKeeperCvp_,
      pendingWithdrawalTimeoutSeconds: pendingWithdrawalTimeoutSeconds_,
      feeTotal: feeTotal_,
      feePpm: feePpm_,
      lastKeeperId: lastKeeperId_
    });
  }

  function getAgentRandaoData(address ppAgentV2) external view returns (
    AgentLightData memory lightData,
    IPPAgentV2RandaoViewer.RandaoConfig memory randaoData
  ) {
    (
      uint256 minKeeperCvp_,
      uint256 pendingWithdrawalTimeoutSeconds_,
      uint256 feeTotal_,
      uint256 feePpm_,
      uint256 lastKeeperId_
    ) = IPPAgentV2Viewer(ppAgentV2).getConfig();

    lightData = AgentLightData({
      latestBlockNumber: block.number,
      cvp: IPPAgentV2Viewer(ppAgentV2).CVP(),
      owner: Ownable(ppAgentV2).owner(),
      minKeeperCvp: minKeeperCvp_,
      pendingWithdrawalTimeoutSeconds: pendingWithdrawalTimeoutSeconds_,
      feeTotal: feeTotal_,
      feePpm: feePpm_,
      lastKeeperId: lastKeeperId_
    });

    randaoData = IPPAgentV2RandaoViewer(ppAgentV2).getRdConfig();
  }
}
