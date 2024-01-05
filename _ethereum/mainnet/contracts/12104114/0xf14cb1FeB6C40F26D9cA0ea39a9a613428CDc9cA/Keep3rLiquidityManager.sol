// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./UtilsReady.sol";

import "./Keep3rLiquidityManagerEscrowsHandler.sol";
import "./Keep3rLiquidityManagerJobHandler.sol";
import "./Keep3rLiquidityManagerJobsLiquidityHandler.sol";
import "./Keep3rLiquidityManagerParameters.sol";
import "./Keep3rLiquidityManagerUserJobsLiquidityHandler.sol";
import "./Keep3rLiquidityManagerUserLiquidityHandler.sol";
import "./Keep3rLiquidityManagerWork.sol";

contract Keep3rLiquidityManager is UtilsReady, Keep3rLiquidityManagerWork, Keep3rLiquidityManagerJobHandler {
  constructor(
    address _keep3rV1,
    address _escrow1,
    address _escrow2
  ) public UtilsReady() Keep3rLiquidityManagerParameters(_keep3rV1) Keep3rLiquidityManagerEscrowsHandler(_escrow1, _escrow2) {}

  // UserLiquidityHandler
  function setLiquidityFee(uint256 _liquidityFee) external override onlyGovernor {
    _setLiquidityFee(_liquidityFee);
  }

  function setFeeReceiver(address _feeReceiver) external override onlyGovernor {
    _setFeeReceiver(_feeReceiver);
  }

  function setMinAmount(address _liquidity, uint256 _minAmount) external override onlyGovernor {
    _setMinAmount(_liquidity, _minAmount);
  }

  // UserJobsLiquidityHandler
  function forceRemoveLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job
  ) external override onlyGovernor {
    _forceRemoveLiquidityOfUserFromJob(_user, _liquidity, _job);
  }

  // Work
  function work(address _job) external override onlyJob {
    (address _escrow, Actions _action) = getNextAction(_job);
    require(_workable(_action), 'Keep3rLiquidityManager::work:not-workable');

    _work(_escrow, _action, _job);

    emit Worked(_job);
  }

  function forceWork(address _job) external override onlyGovernor {
    (address _escrow, Actions _action) = getNextAction(_job);
    _work(_escrow, _action, _job);
    emit ForceWorked(_job);
  }

  function setJob(address _job) external override onlyGovernor {
    _setJob(_job);
  }

  // Collectable Dust
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    require(liquidityTotalAmount[_token] == 0, 'Keep3rLiquidityManager::sendDust:token-is-liquidity');
    _sendDust(_to, _token, _amount);
  }

  // Escrow Liquidity
  function addLiquidityToJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) external override onlyGovernor {
    _addLiquidityToJob(_escrow, _liquidity, _job, _amount);
  }

  function applyCreditToJob(
    address _escrow,
    address _liquidity,
    address _job
  ) external override onlyGovernor {
    _applyCreditToJob(_escrow, _liquidity, _job);
  }

  function unbondLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) external override onlyGovernor {
    _unbondLiquidityFromJob(_escrow, _liquidity, _job, _amount);
  }

  function removeLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job
  ) external override onlyGovernor returns (uint256 _amount) {
    return _removeLiquidityFromJob(_escrow, _liquidity, _job);
  }

  // Escrow Governor
  function setPendingGovernorOnEscrow(address _escrow, address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernorOnEscrow(_escrow, _pendingGovernor);
  }

  function acceptGovernorOnEscrow(address _escrow) external override onlyGovernor {
    _acceptGovernorOnEscrow(_escrow);
  }

  function sendDustOnEscrow(
    address _escrow,
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _sendDustOnEscrow(_escrow, _to, _token, _amount);
  }
}
