// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title PriceBulletin
 *
 * @notice Stores latest price feed round data and provides update methods
 * to rewards update caller.
 * This contract uses a common read methods from Chainlink interface.
 */

import "./IPriceBulletin.sol";
import "./BulletinSigning.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AppStorage.sol";

contract PriceBulletin is IPriceBulletin, UUPSUpgradeable, OwnableUpgradeable, BulletinSigning {
  using SafeERC20 for IERC20;

  /// Events
  event BulletinUpdated(uint80 indexed rounId, int256 answer);
  event FailedBulletinUpdate(string err);
  event EarnedReward(address indexed owner, address indexed token, uint256 amount);
  event ClaimedReward(address indexed owner, address indexed token, uint256 amount);
  event SetAuthorizedPublisher(address publisher, bool status);
  event SetReward(address token, uint256 amount);

  /// Errors
  error PriceBulletin__checkRewardTokenAndAmount_noRewardTokenOrAmount();
  error PriceBulletin__distributeReward_notEnoughPendingRewards();
  error PriceBulletin__distributeReward_notEnoughRewardBalance();
  error PriceBulletin__invalidInput();
  error PriceBulletin__setter_noChange();

  bytes32 private constant CUICA_DOMAIN = keccak256(
    abi.encode(
      TYPEHASH,
      NAMEHASH,
      VERSIONHASH,
      address(0x8f78dc290e1701EC664909410661DC17E9c7b62b),
      keccak256(abi.encode(0x64))
    )
  );

  RoundData private _recordedRoundInfo;

  mapping(address => bool) public authorizedPublishers;

  ///@notice Maps `user`  => `reward token` => `amount` of pending rewards
  mapping(address => mapping(IERC20 => uint256)) private _rewards;

  IERC20 public rewardToken;

  uint256 public rewardAmount;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() external initializer {
    __Ownable_init();
  }

  /**
   * @inheritdoc IAggregatorV3
   */
  function decimals() external pure returns (uint8) {
    return 8;
  }

  /**
   * @inheritdoc IAggregatorV3
   */
  function description() external pure returns (string memory) {
    return "priceBulletin MXN / USD";
  }

  /**
   * @inheritdoc IAggregatorV3
   */
  function version() external pure returns (string memory) {
    return VERSION;
  }

  /**
   * @notice Returns only `answer` from `latestRoundData()`
   * This method is kept for compatibility with older contracts.
   */
  function latestAnswer() external view returns (int256) {
    (, int256 answer,,,) = latestRoundData();
    return answer;
  }

  /**
   * @notice Returns the latest `roundId`
   */
  function latestRound() public view returns (uint80) {
    return _recordedRoundInfo.roundId;
  }

  /**
   * @inheritdoc IAggregatorV3
   */
  function latestRoundData()
    public
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint80 lastRound = latestRound();

    if (lastRound == 0) {
      return (0, 0, 0, 0, 0);
    } else {
      return (
        lastRound,
        _recordedRoundInfo.answer,
        _recordedRoundInfo.startedAt,
        _recordedRoundInfo.updatedAt,
        lastRound
      );
    }
  }

  /**
   * @inheritdoc IXReceiver
   */
  function xReceive(
    bytes32 transferId,
    uint256,
    address,
    address,
    uint32,
    bytes memory callData
  )
    external
    returns (bytes memory)
  {
    updateBulletin(callData);
    return abi.encode(transferId);
  }

  /**
   * @notice Updates the price bulletin with latest round and sets `_recordedRoundInfo`.
   * The most gas efficient to update price bulletin with no log or claim for rewards.
   *
   * @param callData encoded RounData with v,r,s signature values
   *
   * @dev Function restricts using the same or old RoundData.
   * Requirements:
   * - Must never revert provided the `callData` is properly feeded for decoding
   * - Must emit a `BulletinUpdated` event if updating bulletin is succesfull
   * - Must emit a `FailedBulletinUpdate` event if updated bulletin failed
   */
  function updateBulletin(bytes memory callData) public returns (bool success) {
    (RoundData memory round, uint8 v, bytes32 r, bytes32 s) =
      abi.decode(callData, (RoundData, uint8, bytes32, bytes32));

    (bool valid, string memory err) = _checkValidBulletinUpdateData(round, v, r, s);

    if (valid) {
      success = true;
      emit BulletinUpdated(round.roundId, round.answer);
    } else {
      emit FailedBulletinUpdate(err);
    }
  }

  /**
   * @notice Same as `updateBulletin()`, but logging a claim for rewards.
   * Rewards earned by calling this method can be claimed at a later point using
   * the `claimRewards()` method.
   *
   * @param callData encoded RounData with v,r,s signature values
   *
   * @dev Requirements:
   * - Must revert if no reward token or amount are set
   */
  function updateBulletinWithRewardLog(bytes memory callData) public returns (bool success) {
    if (updateBulletin(callData)) {
      _logEarnedReward(msg.sender, rewardToken, rewardAmount);
      success = true;
    }
  }

  /**
   * @notice Same as `updateBulletin()`, but logs and simultaneaously claims reward.
   *
   * @param callData encoded RounData with v,r,s signature values
   * @param receiver of the claimed reward
   *
   * @dev Reverts if no reward settings or reward balance is available.
   */
  function updateBulletinWithRewardClaim(
    bytes memory callData,
    address receiver
  )
    public
    returns (bool success)
  {
    if (updateBulletinWithRewardLog(callData)) {
      _distributeReward(msg.sender, receiver, rewardToken, rewardAmount);
      success = true;
    }
  }

  /**
   * @notice Returns the amount of pending rewards for specific `rewardToken` for `user`.
   *
   * @param user_ to check pending rewards
   * @param rewardToken_ reward token
   */
  function getRewards(address user_, address rewardToken_) public view returns (uint256) {
    return _rewards[user_][IERC20(rewardToken_)];
  }

  /**
   * @notice Claims earned rewards for `msg.sender` and sends them to `receiver`.
   *
   * @param receiver of the claim rewards
   * @param token of reward
   * @param amount of reward to claim
   *
   * @dev Requirements:
   * - Must revert if receiver, token or amount are zero.
   */
  function claimRewards(address receiver, IERC20 token, uint256 amount) public {
    _distributeReward(msg.sender, receiver, token, amount);
  }

  /**
   * @inheritdoc IPriceBulletin
   */
  function setAuthorizedPublisher(address publisher, bool set) external onlyOwner {
    if (publisher == address(0)) {
      revert PriceBulletin__invalidInput();
    }
    if (authorizedPublishers[publisher] == set) {
      revert PriceBulletin__setter_noChange();
    }

    authorizedPublishers[publisher] = set;

    emit SetAuthorizedPublisher(publisher, set);
  }

  /**
   * @notice Sets the active `rewardToken` and `rewardAmount` for updating
   * this {PriceBulletin} contract.
   *
   * @param token of reward
   * @param amount of reward
   *
   * @dev Requirements:
   * - Must emit a `SetReward` event
   * - Must revert if token or amount are zero
   * - Must be restricted to `onlyOwner`
   */
  function setReward(IERC20 token, uint256 amount) public onlyOwner {
    _checkRewardTokenAndAmount(token, amount);
    rewardToken = token;
    rewardAmount = amount;
    emit SetReward(address(token), amount);
  }

  /**
   * @notice Returns true or false and error if data is valid and signer is
   * an allowed publisher
   *
   * @param round struct data
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must never revert
   * - Must check signer is a valid publisher
   * - Must check round id is the next or higher round
   */
  function _checkValidBulletinUpdateData(
    RoundData memory round,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    internal
    returns (bool valid, string memory err)
  {
    uint80 currentRoundId = _recordedRoundInfo.roundId;
    uint80 newRoundId = round.roundId;

    bytes32 structHash = getStructHashRoundData(round);
    address presumedSigner = _getSigner(structHash, v, r, s);

    if (currentRoundId >= newRoundId) {
      valid = false;
      err = "Bad RoundId!";
    } else if (!authorizedPublishers[presumedSigner]) {
      valid = false;
      err = "Bad publisher!";
    } else {
      _recordedRoundInfo = round;
      valid = true;
      err = "";
    }
  }

  /**
   * @dev Logs earned rewards.
   *
   * @param user earning rewards
   * @param token of rewards
   * @param amount of rewards
   *
   * Requirements:
   * - Must emit a `EarnedReward` event
   * - Must revert if user, token or amount are zero
   * - Must update `rewards` state
   */
  function _logEarnedReward(address user, IERC20 token, uint256 amount) internal {
    if (user == address(0)) {
      revert PriceBulletin__invalidInput();
    }
    _checkRewardTokenAndAmount(token, amount);
    _rewards[user][token] += amount;
    emit EarnedReward(user, address(token), amount);
  }

  /**
   * @dev Distributes a claim for rewards.
   *
   * @param user owning the rewards
   * @param receiver of the claimed rewards
   * @param token of reward
   * @param amount of reward
   *
   * Requirements:
   * - Must emit a `ClaimedRewards` event
   * - Must revert if receiver, token or amount are zero.
   * - Must revert if `amount` is greater than corresponding `_rewards` state
   * - Must update `_rewards` state before sending tokens.
   * - Must use "Safe" transfer method.
   */
  function _distributeReward(address user, address receiver, IERC20 token, uint256 amount) internal {
    if (receiver == address(0)) {
      revert PriceBulletin__invalidInput();
    }
    _checkRewardTokenAndAmount(token, amount);

    uint256 pendingRewards = _rewards[user][token];

    if (pendingRewards < amount) {
      revert PriceBulletin__distributeReward_notEnoughPendingRewards();
    }

    _rewards[user][token] = pendingRewards - amount;

    if (token.balanceOf(address(this)) < amount) {
      revert PriceBulletin__distributeReward_notEnoughRewardBalance();
    }

    token.safeTransfer(receiver, amount);

    emit ClaimedReward(user, address(token), amount);
  }

  /**
   * @dev Reverts if inputs are zero.
   *
   * @param token to check
   * @param amount to check
   */
  function _checkRewardTokenAndAmount(IERC20 token, uint256 amount) private pure {
    if (address(token) == address(0) || amount == 0) {
      revert PriceBulletin__checkRewardTokenAndAmount_noRewardTokenOrAmount();
    }
  }

  /**
   * @dev Returns the signer of the`structHash`.
   *
   * @param structHash of data
   * @param v signature value
   * @param r signautre value
   * @param s signature value
   */
  function _getSigner(
    bytes32 structHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    internal
    view
    returns (address presumedSigner)
  {
    bytes32 digest = getHashTypedDataV4Digest(structHash);
    presumedSigner = ECDSA.recover(digest, v, r, s);
  }

  /**
   * @inheritdoc BulletinSigning
   */
  function _getDomainSeparator() internal pure override returns (bytes32) {
    return CUICA_DOMAIN;
  }

  /**
   * @inheritdoc UUPSUpgradeable
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
