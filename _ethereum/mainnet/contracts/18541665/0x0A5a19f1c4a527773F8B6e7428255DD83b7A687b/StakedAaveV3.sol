// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./DistributionTypes.sol";
import "./StakedTokenV3.sol";
import "./IGhoVariableDebtTokenTransferHook.sol";
import "./SafeCast.sol";
import "./IStakedAaveV3.sol";

/**
 * @title StakedAaveV3
 * @notice StakedTokenV3 with AAVE token as staked token
 * @author BGD Labs
 */
contract StakedAaveV3 is StakedTokenV3, IStakedAaveV3 {
  using SafeCast for uint256;

  uint256[1] private ______DEPRECATED_FROM_STK_AAVE_V3;

  /// @notice GHO debt token to be used in the _beforeTokenTransfer hook
  IGhoVariableDebtTokenTransferHook public ghoDebtToken;

  function REVISION() public pure virtual override returns (uint256) {
    return 6;
  }

  constructor(
    IERC20 stakedToken,
    IERC20 rewardToken,
    uint256 unstakeWindow,
    address rewardsVault,
    address emissionManager,
    uint128 distributionDuration
  )
    StakedTokenV3(
      stakedToken,
      rewardToken,
      unstakeWindow,
      rewardsVault,
      emissionManager,
      distributionDuration
    )
  {
    // brick initialize
    lastInitializedRevision = REVISION();
  }

  /**
   * @dev Called by the proxy contract
   */
  function initialize() external override initializer {}

  /// @inheritdoc IStakedAaveV3
  function claimRewardsAndStake(
    address to,
    uint256 amount
  ) external override returns (uint256) {
    return _claimRewardsAndStakeOnBehalf(msg.sender, to, amount);
  }

  /// @inheritdoc IStakedAaveV3
  function claimRewardsAndStakeOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external override onlyClaimHelper returns (uint256) {
    return _claimRewardsAndStakeOnBehalf(from, to, amount);
  }

  /**
   * - On _transfer, it updates discount, rewards & delegation for both "from" and "to"
   * - On _mint, only for _to
   * - On _burn, only for _from
   * @param from token sender
   * @param to token recipient
   * @param fromBalanceBefore balance of the sender before transfer
   * @param toBalanceBefore balance of the recipient before transfer
   * @param amount amount of tokens sent
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 fromBalanceBefore,
    uint256 toBalanceBefore,
    uint256 amount
  ) internal override {
    super._afterTokenTransfer(
      from,
      to,
      fromBalanceBefore,
      toBalanceBefore,
      amount
    );

    IGhoVariableDebtTokenTransferHook cachedGhoDebtToken = ghoDebtToken;
    if (address(cachedGhoDebtToken) != address(0)) {
      try
        cachedGhoDebtToken.updateDiscountDistribution(
          from,
          to,
          fromBalanceBefore,
          toBalanceBefore,
          amount
        )
      {} catch (bytes memory) {}
    }
  }
}
