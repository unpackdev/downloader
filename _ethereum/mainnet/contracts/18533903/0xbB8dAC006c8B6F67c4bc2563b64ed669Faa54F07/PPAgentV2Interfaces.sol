// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPPAgentV2Executor {
  function execute_44g58pv() external;
}

interface IPPAgentV2Viewer {
  struct Job {
    uint8 config;
    bytes4 selector;
    uint88 credits;
    uint16 maxBaseFeeGwei;
    uint16 rewardPct;
    uint32 fixedReward;
    uint8 calldataSource;

    // For interval jobs
    uint24 intervalSeconds;
    uint32 lastExecutionAt;
  }

  struct Resolver {
    address resolverAddress;
    bytes resolverCalldata;
  }

  function getConfig() external view returns (
    uint256 minKeeperCvp_,
    uint256 pendingWithdrawalTimeoutSeconds_,
    uint256 feeTotal_,
    uint256 feePpm_,
    uint256 lastKeeperId_
  );
  function getKeeper(uint256 keeperId_) external view returns (
    address admin,
    address worker,
    bool isActive,
    uint256 currentStake,
    uint256 slashedStake,
    uint256 compensation,
    uint256 pendingWithdrawalAmount,
    uint256 pendingWithdrawalEndAt
  );
  function getKeeperWorkerAndStake(uint256 keeperId_) external view returns (
    address worker,
    uint256 currentStake,
    bool isActive
  );
  function getJob(bytes32 jobKey_) external view returns (
    address owner,
    address pendingTransfer,
    uint256 jobLevelMinKeeperCvp,
    Job memory details,
    bytes memory preDefinedCalldata,
    Resolver memory resolver
  );
  function getJobRaw(bytes32 jobKey_) external view returns (uint256 rawJob);
  function jobOwnerCredits(address owner_) external view returns (uint256 credits);
  function getStrategy() external pure returns (string memory);
  function CVP() external view returns (address);
}

interface IPPAgentV2JobOwner {
  struct RegisterJobParams {
    address jobAddress;
    bytes4 jobSelector;
    bool useJobOwnerCredits;
    bool assertResolverSelector;
    uint16 maxBaseFeeGwei;
    uint16 rewardPct;
    uint32 fixedReward;
    uint256 jobMinCvp;
    uint8 calldataSource;
    uint24 intervalSeconds;
  }
}

interface IPPAgentV2RandaoViewer {
  // 8+24+16+24+16+16+40+16+32+8+24 = 224
  struct RandaoConfig {
    // max: 2^8 - 1 = 255 blocks
    uint8 slashingEpochBlocks;
    // max: 2^24 - 1 = 16777215 seconds ~ 194 days
    uint24 period1;
    // max: 2^16 - 1 = 65535 seconds ~ 18 hours
    uint16 period2;
    // in 1 CVP. max: 16_777_215 CVP. The value here is multiplied by 1e18 in calculations.
    uint24 slashingFeeFixedCVP;
    // In BPS
    uint16 slashingFeeBps;
    // max: 2^16 - 1 = 65535, in calculations is multiplied by 0.001 ether (1 finney),
    // thus the min is 0.001 ether and max is 65.535 ether
    uint16 jobMinCreditsFinney;
    // max 2^40 ~= 1.1e12, in calculations is multiplied by 1 ether
    uint40 agentMaxCvpStake;
    // max: 2^16 - 1 = 65535, where 10_000 is 100%
    uint16 jobCompensationMultiplierBps;
    // max: 2^32 - 1 = 4_294_967_295
    uint32 stakeDivisor;
    // max: 2^8 - 1 = 255 hours, or ~10.5 days
    uint8 keeperActivationTimeoutHours;
    // max: 2^16 - 1 = 65535, in calculations is multiplied by 0.001 ether (1 finney),
    // thus the min is 0.001 ether and max is 65.535 ether
    uint16 jobFixedRewardFinney;
  }

  function getRdConfig() external view returns (RandaoConfig memory);
  function getJobsAssignedToKeeper(uint256 keeperId_) external view returns (bytes32[] memory jobKeys);
  function getJobsAssignedToKeeperLength(uint256 keeperId_) external view returns (uint256);
  function getCurrentSlasherId(bytes32 jobKey_) external view returns (uint256);
  function getActiveKeepersLength() external view returns (uint256);
  function getActiveKeepers() external view returns (uint256[] memory);
  function getSlasherIdByBlock(uint256 blockNumber_, bytes32 jobKey_) external view returns (uint256);

  function jobNextKeeperId(bytes32 jobKey_) external view returns (uint256);
  function jobReservedSlasherId(bytes32 jobKey_) external view returns (uint256);
  function jobSlashingPossibleAfter(bytes32 jobKey_) external view returns (uint256);
  function jobCreatedAt(bytes32 jobKey_) external view returns (uint256);
  function keeperActivationCanBeFinalizedAt(uint256 keeperId_) external view returns (uint256);
}

interface IPPGasUsedTracker {
  function notify(uint256 keeperId_, uint256 gasUsed_) external;
}