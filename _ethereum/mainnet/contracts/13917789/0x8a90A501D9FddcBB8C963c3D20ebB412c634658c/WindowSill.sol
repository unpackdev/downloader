
// SPDX-License-Identifier: MIT
import "./IERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./Math.sol";
import "./SafeCast.sol";

pragma solidity ^0.8.0;

contract TheWindowSill {

  using SafeCast for uint256;

  event Initialized(
    address moodyMonsterasToken,
    address vibesToken,
    address vibesTokenHolder,
    uint256 rewardPerTokenPerSecond,
    uint256 startTime,
    uint256 endTime
  );
  event Staked(address indexed staker, uint256 indexed tokenId, uint256 indexed timestamp);
  event Unstaked(address indexed staker, uint256 indexed tokenId, uint256 indexed timestamp);
  event ClaimedReward(address indexed staker, uint256 indexed amount, uint256 indexed timestamp);

  struct StakerInfo {
    uint32 lastActionTime;
    uint32 stakedCount;
    uint128 accumulatedReward;
  }

  IERC721 public moodyMonsterasToken;
  IERC20 public vibesToken;
  address public vibesTokenHolder;
  uint256 public rewardPerTokenPerSecond;
  uint256 public startTime;
  uint256 public endTime;

  mapping(address => StakerInfo) public stakerInfos;
  mapping(uint256 => address) public tokenOwners;

  modifier onlyStarted() {
    require(block.timestamp >= startTime, "Sill: not started");
    _;
  }

  modifier onlyNotEnded() {
    require(block.timestamp < endTime, "Sill: already ended");
    _;
  }

  function getReward(address staker) external view returns (uint256) {
    StakerInfo memory stakerInfo = stakerInfos[staker];
    return
      uint256(stakerInfo.accumulatedReward) +
      calculateEffectiveTimeElapsed(stakerInfo.lastActionTime) *
      uint256(stakerInfo.stakedCount) *
      rewardPerTokenPerSecond;
  }

  constructor(
    IERC721 _moodyMonsterasToken,
    IERC20 _vibesToken,
    address _vibesTokenHolder,
    uint256 _rewardPerTokenPerSecond,
    uint256 _startTime,
    uint256 _endTime
  ) {
      require(address(_moodyMonsterasToken) != address(0), "Sill: zero address");
      require(address(_vibesToken) != address(0), "Sill: zero address");
      require(address(_vibesTokenHolder) != address(0), "Sill: zero address");
      require(_rewardPerTokenPerSecond > 0, "Sill: reward per second cannot be zero");
      require(_endTime > _startTime, "Sill: invalid time range");

      moodyMonsterasToken = _moodyMonsterasToken;
      vibesToken = _vibesToken;
      vibesTokenHolder = _vibesTokenHolder;
      rewardPerTokenPerSecond = _rewardPerTokenPerSecond;
      startTime = _startTime;
      endTime = _endTime;

      emit Initialized(
        address(moodyMonsterasToken),
        address(vibesToken),
        vibesTokenHolder,
        rewardPerTokenPerSecond,
        startTime,
        endTime
      );
  }

  function stake(uint256[] calldata tokenIds) external onlyStarted onlyNotEnded {
    for (uint256 ind = 0; ind < tokenIds.length; ind++) {
      doStake(msg.sender, tokenIds[ind]);
    }
  }

  function unstake(uint256[] calldata tokenIds) external onlyStarted {
    for (uint256 ind = 0; ind < tokenIds.length; ind++) {
      doUnstake(msg.sender, tokenIds[ind]);
    }
  }

  function claimRewards() external {
    doClaimRewards(msg.sender);
  }

  function doStake(address staker, uint256 tokenId) private {
    settleRewards(staker);

    stakerInfos[staker].stakedCount += 1;
    tokenOwners[tokenId] = staker;

    moodyMonsterasToken.transferFrom(staker, address(this), tokenId);

    emit Staked(staker, tokenId, block.timestamp);
  }

  function doUnstake(address staker, uint256 tokenId) private {
    settleRewards(staker);

    require(tokenOwners[tokenId] == staker, "Sill: not token owner");

    stakerInfos[staker].stakedCount -= 1;
    delete tokenOwners[tokenId];

    moodyMonsterasToken.transferFrom(address(this), staker, tokenId);

    emit Unstaked(staker, tokenId, block.timestamp);
  }

  function doClaimRewards(address staker) private {
    settleRewards(staker);

    uint256 accumulatedRewards = uint256(stakerInfos[staker].accumulatedReward);
    require(accumulatedRewards > 0, "Sill: no reward to claim");

    stakerInfos[staker].accumulatedReward = 0;

    vibesToken.transferFrom(vibesTokenHolder, staker, accumulatedRewards);

    emit ClaimedReward(staker, accumulatedRewards, block.timestamp);
  }

  function settleRewards(address staker) private {
    uint32 blockTimestamp = block.timestamp.toUint32();
    StakerInfo memory stakerInfo = stakerInfos[staker];

    // No need to update anything if no time has elapsed since last time
    if (stakerInfo.lastActionTime != blockTimestamp) {
      stakerInfos[staker].lastActionTime = block.timestamp.toUint32();

      // Only update rewards if anything was staked
      if (stakerInfo.stakedCount > 0) {
        stakerInfos[staker].accumulatedReward =
          stakerInfo.accumulatedReward +
          calculateEffectiveTimeElapsed(stakerInfo.lastActionTime).toUint128() *
          uint128(stakerInfo.stakedCount) *
          rewardPerTokenPerSecond.toUint128();
      }
    }
  }

  function calculateEffectiveTimeElapsed(uint32 lastActionTime) private view returns (uint256) {
    uint256 effectiveTimestamp = Math.min(block.timestamp, endTime);
    return effectiveTimestamp > lastActionTime ? effectiveTimestamp - lastActionTime : 0;
  }

}
