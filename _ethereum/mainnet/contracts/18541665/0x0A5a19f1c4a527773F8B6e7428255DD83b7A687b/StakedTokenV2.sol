// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./EIP712.sol";
import "./IStakedTokenV2.sol";

import "./DistributionTypes.sol";
import "./SafeERC20.sol";

import "./VersionedInitializable.sol";
import "./AaveDistributionManager.sol";
import "./GovernancePowerWithSnapshot.sol";
import "./BaseMintableAaveToken.sol";

/**
 * @title StakedTokenV2
 * @notice Contract to stake Aave token, tokenize the position and get rewards, inheriting from a distribution manager contract
 * @author BGD Labs
 */
abstract contract StakedTokenV2 is
  IStakedTokenV2,
  BaseMintableAaveToken,
  GovernancePowerWithSnapshot,
  VersionedInitializable,
  AaveDistributionManager,
  EIP712
{
  using SafeERC20 for IERC20;

  IERC20 public immutable STAKED_TOKEN;
  IERC20 public immutable REWARD_TOKEN;

  /// @notice Seconds available to redeem once the cooldown period is fulfilled
  uint256 public immutable UNSTAKE_WINDOW;

  /// @notice Address to pull from the rewards, needs to have approved this contract
  address public immutable REWARDS_VAULT;

  mapping(address => uint256) public stakerRewardsToClaim;
  mapping(address => CooldownSnapshot) public stakersCooldowns;

  /// @dev End of Storage layout from StakedToken v1
  uint256[5] private ______DEPRECATED_FROM_STK_AAVE_V2;

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256(
      'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
    );

  /// @dev owner => next valid nonce to submit with permit()
  mapping(address => uint256) public _nonces;

  constructor(
    IERC20 stakedToken,
    IERC20 rewardToken,
    uint256 unstakeWindow,
    address rewardsVault,
    address emissionManager,
    uint128 distributionDuration
  )
    AaveDistributionManager(emissionManager, distributionDuration)
    EIP712('Staked Aave', '2')
  {
    STAKED_TOKEN = stakedToken;
    REWARD_TOKEN = rewardToken;
    UNSTAKE_WINDOW = unstakeWindow;
    REWARDS_VAULT = rewardsVault;
  }

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return _domainSeparatorV4();
  }

  /// @dev maintained for backwards compatibility. See EIP712 _EIP712Version
  function EIP712_REVISION() external view returns (bytes memory) {
    return bytes(_EIP712Version());
  }

  /// @inheritdoc IStakedTokenV2
  function stake(address onBehalfOf, uint256 amount) external virtual override;

  /// @inheritdoc IStakedTokenV2
  function redeem(address to, uint256 amount) external virtual override;

  /// @inheritdoc IStakedTokenV2
  function cooldown() external virtual override;

  /// @inheritdoc IStakedTokenV2
  function claimRewards(address to, uint256 amount) external virtual override;

  /// @inheritdoc IStakedTokenV2
  function getTotalRewardsBalance(
    address staker
  ) external view returns (uint256) {
    DistributionTypes.UserStakeInput[]
      memory userStakeInputs = new DistributionTypes.UserStakeInput[](1);
    userStakeInputs[0] = DistributionTypes.UserStakeInput({
      underlyingAsset: address(this),
      stakedByUser: balanceOf(staker),
      totalStaked: totalSupply()
    });
    return
      stakerRewardsToClaim[staker] +
      _getUnclaimedRewards(staker, userStakeInputs);
  }

  /// @inheritdoc IStakedTokenV2
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(owner != address(0), 'INVALID_OWNER');
    //solium-disable-next-line
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          PERMIT_TYPEHASH,
          owner,
          spender,
          value,
          currentValidNonce,
          deadline
        )
      )
    );

    require(owner == ECDSA.recover(digest, v, r, s), 'INVALID_SIGNATURE');
    unchecked {
      _nonces[owner] = currentValidNonce + 1;
    }
    _approve(owner, spender, value);
  }

  /**
   * @dev Updates the user state related with his accrued rewards
   * @param user Address of the user
   * @param userBalance The current balance of the user
   * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
   * @return The unclaimed rewards that were added to the total accrued
   */
  function _updateCurrentUnclaimedRewards(
    address user,
    uint256 userBalance,
    bool updateStorage
  ) internal returns (uint256) {
    uint256 accruedRewards = _updateUserAssetInternal(
      user,
      address(this),
      userBalance,
      totalSupply()
    );
    uint256 unclaimedRewards = stakerRewardsToClaim[user] + accruedRewards;

    if (accruedRewards != 0) {
      if (updateStorage) {
        stakerRewardsToClaim[user] = unclaimedRewards;
      }
      emit RewardsAccrued(user, accruedRewards);
    }

    return unclaimedRewards;
  }
}
