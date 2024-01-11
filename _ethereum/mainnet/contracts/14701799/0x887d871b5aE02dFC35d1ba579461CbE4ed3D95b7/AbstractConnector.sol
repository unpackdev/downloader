// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./WrappedPiErc20Interface.sol";
import "./IRouterConnector.sol";

/**
 * @notice Connectors execute staking strategies by calling from PowerIndexRouter with delegatecall. Therefore,
 * connector contracts should not have any rights stored in other contracts. Instead, rights for connector logic
 * must be provided to PowerIndexRouter by proxy pattern, where the router is a proxy, and the connectors are
 * implementations. Every connector implementation has unique staking logic for stake, redeem, beforePoke, and
 * afterPoke functions, that returns data to save in PowerIndexRouter storage because connectors don't have any
 * storage.
 */
abstract contract AbstractConnector is IRouterConnector {
  using SafeMath for uint256;

  uint256 public constant DEGRADATION_COEFFICIENT = 1 ether;
  uint256 public constant HUNDRED_PCT = 1 ether;
  uint256 public immutable LOCKED_PROFIT_DEGRADATION;

  event Stake(address indexed sender, address indexed staking, address indexed underlying, uint256 amount);
  event Redeem(address indexed sender, address indexed staking, address indexed underlying, uint256 amount);

  event DistributeReward(
    address indexed sender,
    uint256 totalReward,
    uint256 performanceFee,
    uint256 piTokenReward,
    uint256 lockedProfitBefore,
    uint256 lockedProfitAfter
  );

  event DistributePerformanceFee(
    uint256 performanceFeeDebtBefore,
    uint256 performanceFeeDebtAfter,
    uint256 underlyingBalance,
    uint256 performance
  );

  constructor(uint256 _lockedProfitDegradation) public {
    LOCKED_PROFIT_DEGRADATION = _lockedProfitDegradation;
  }

  /**
   * @notice Call external contract by piToken (piERC20) contract.
   * @param _piToken piToken(piERC20) to call from.
   * @param _contract Contract to call.
   * @param _sig Function signature to call.
   * @param _data Data of function arguments to call.
   * @return Data returned from contract.
   */
  function _callExternal(
    WrappedPiErc20Interface _piToken,
    address _contract,
    bytes4 _sig,
    bytes memory _data
  ) internal returns (bytes memory) {
    return _piToken.callExternal(_contract, _sig, _data, 0);
  }

  /**
   * @notice Distributes performance fee from reward and calculates locked profit.
   * @param _distributeData Data is stored in the router contract and passed to the connector's functions.
   * @param _piToken piToken(piERC20) address.
   * @param _token ERC20 Token address to distribute reward.
   * @param _totalReward Total reward received
   * @return lockedProfitReward Rewards that locked in vesting.
   * @return stakeData Result packed rewards data.
   */
  function _distributeReward(
    DistributeData memory _distributeData,
    WrappedPiErc20Interface _piToken,
    IERC20 _token,
    uint256 _totalReward
  ) internal returns (uint256 lockedProfitReward, bytes memory stakeData) {
    (uint256 lockedProfit, uint256 lastRewardDistribution, uint256 performanceFeeDebt) = unpackStakeData(
      _distributeData.stakeData
    );
    uint256 pvpReward;
    // Step #1. Distribute pvpReward
    (pvpReward, lockedProfitReward, performanceFeeDebt) = _distributePerformanceFee(
      _distributeData.performanceFee,
      _distributeData.performanceFeeReceiver,
      performanceFeeDebt,
      _piToken,
      _token,
      _totalReward
    );
    require(lockedProfitReward > 0, "NO_POOL_REWARDS_UNDERLYING");

    // Step #2 Reset lockedProfit
    uint256 lockedProfitBefore = calculateLockedProfit(lockedProfit, lastRewardDistribution);
    uint256 lockedProfitAfter = lockedProfitBefore.add(lockedProfitReward);
    lockedProfit = lockedProfitAfter;

    lastRewardDistribution = block.timestamp;

    emit DistributeReward(
      msg.sender,
      _totalReward,
      pvpReward,
      lockedProfitReward,
      lockedProfitBefore,
      lockedProfitAfter
    );

    return (lockedProfitReward, packStakeData(lockedProfit, lastRewardDistribution, performanceFeeDebt));
  }

  /**
   * @notice Distributes performance fee from reward.
   * @param _performanceFee Share of fee to subtract as performance fee.
   * @param _performanceFeeReceiver Receiver of performance fee.
   * @param _performanceFeeDebt Performance fee amount left from last distribution.
   * @param _piToken piToken(piERC20).
   * @param _underlying Underlying ERC20 token.
   * @param _totalReward Total reward amount.
   * @return performance Fee amount calculated to distribute.
   * @return remainder Diff between total reward amount and performance fee.
   * @return resultPerformanceFeeDebt Not yet distributed performance amount due to insufficient balance on
   *         piToken (piERC20).
   */
  function _distributePerformanceFee(
    uint256 _performanceFee,
    address _performanceFeeReceiver,
    uint256 _performanceFeeDebt,
    WrappedPiErc20Interface _piToken,
    IERC20 _underlying,
    uint256 _totalReward
  )
    internal
    returns (
      uint256 performance,
      uint256 remainder,
      uint256 resultPerformanceFeeDebt
    )
  {
    performance = 0;
    remainder = 0;
    resultPerformanceFeeDebt = _performanceFeeDebt;

    if (_performanceFee > 0) {
      performance = _totalReward.mul(_performanceFee).div(HUNDRED_PCT);
      remainder = _totalReward.sub(performance);

      uint256 performanceFeeDebtBefore = _performanceFeeDebt;
      uint256 underlyingBalance = _underlying.balanceOf(address(_piToken));
      uint256 totalFeeToPayOut = performance.add(performanceFeeDebtBefore);
      if (underlyingBalance >= totalFeeToPayOut) {
        _safeTransfer(_piToken, _underlying, _performanceFeeReceiver, totalFeeToPayOut);
      } else {
        resultPerformanceFeeDebt = totalFeeToPayOut.sub(underlyingBalance);
        _safeTransfer(_piToken, _underlying, _performanceFeeReceiver, underlyingBalance);
      }

      emit DistributePerformanceFee(performanceFeeDebtBefore, resultPerformanceFeeDebt, underlyingBalance, performance);
    } else {
      remainder = _totalReward;
    }
  }

  /**
   * @notice Pack stake data to bytes.
   */
  function packStakeData(
    uint256 lockedProfit,
    uint256 lastRewardDistribution,
    uint256 performanceFeeDebt
  ) public pure returns (bytes memory) {
    return abi.encode(lockedProfit, lastRewardDistribution, performanceFeeDebt);
  }

  /**
   * @notice Unpack stake data from bytes to variables.
   */
  function unpackStakeData(bytes memory _stakeData)
    public
    pure
    returns (
      uint256 lockedProfit,
      uint256 lastRewardDistribution,
      uint256 performanceFeeDebt
    )
  {
    if (_stakeData.length == 0 || keccak256(_stakeData) == keccak256("")) {
      return (0, 0, 0);
    }
    (lockedProfit, lastRewardDistribution, performanceFeeDebt) = abi.decode(_stakeData, (uint256, uint256, uint256));
  }

  /**
   * @notice Calculate locked profit from packed _stakeData.
   */
  function calculateLockedProfit(bytes memory _stakeData) external view override returns (uint256) {
    (uint256 lockedProfit, uint256 lastRewardDistribution, ) = unpackStakeData(_stakeData);
    return calculateLockedProfit(lockedProfit, lastRewardDistribution);
  }

  /**
   * @notice Calculate locked profit based on lastRewardDistribution timestamp.
   * @param _lockedProfit Previous locked profit amount.
   * @param _lastRewardDistribution Timestamp of last rewards distribution.
   * @return Updated locked profit amount, calculated with past time from _lastRewardDistribution.
   */
  function calculateLockedProfit(uint256 _lockedProfit, uint256 _lastRewardDistribution) public view returns (uint256) {
    uint256 lockedFundsRatio = (block.timestamp.sub(_lastRewardDistribution)).mul(LOCKED_PROFIT_DEGRADATION);

    if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
      uint256 currentLockedProfit = _lockedProfit;
      return currentLockedProfit.sub(lockedFundsRatio.mul(currentLockedProfit) / DEGRADATION_COEFFICIENT);
    } else {
      return 0;
    }
  }

  /**
   * @notice Transfer token amount from piToken(piERC20) to destination.
   * @param _piToken piToken(piERC20).
   * @param _token ERC20 token address.
   * @param _to Destination address.
   * @param _value Amount to transfer.
   */
  function _safeTransfer(
    WrappedPiErc20Interface _piToken,
    IERC20 _token,
    address _to,
    uint256 _value
  ) internal {
    bytes memory response = _piToken.callExternal(
      address(_token),
      IERC20.transfer.selector,
      abi.encode(_to, _value),
      0
    );

    if (response.length > 0) {
      // Return data is optional
      require(abi.decode(response, (bool)), "ERC20 operation did not succeed");
    }
  }

  function isClaimAvailable(
    bytes calldata _claimParams, // solhint-disable-line
    uint256 _lastClaimRewardsAt, // solhint-disable-line
    uint256 _lastChangeStakeAt // solhint-disable-line
  ) external view virtual override returns (bool) {
    return true;
  }
}
