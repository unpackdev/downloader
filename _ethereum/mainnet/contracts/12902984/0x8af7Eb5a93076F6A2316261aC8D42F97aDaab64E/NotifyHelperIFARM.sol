pragma solidity 0.5.16;

import "./Controllable.sol";
import "./IFeeRewardForwarder.sol";
import "./SafeERC20.sol";

interface INotifyHelperRegular {
  function feeRewardForwarder() external view returns (address);
}

contract NotifyHelperIFARM is Controllable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public notifyHelperRegular;
  address public farm;
  mapping (address => bool) public alreadyNotified;
  mapping (address => uint256) public mostRecentWeeklyFarm;
  mapping (address => uint256) public mostRecentWeeklyFarmTime;

  constructor(address _storage, address _notifyHelperRegular, address _farm)
  Controllable(_storage) public {
    // used for getting a reference to FeeRewardForwarder
    notifyHelperRegular = _notifyHelperRegular;
    farm = _farm;
  }

  /**
  * Notifies all the pools through Fee Reward Forwarder, safe guarding the notification amount.
  */
  function notifyPools(uint256[] memory amounts,
    address[] memory pools,
    uint256 sum
  ) public onlyGovernance {
    INotifyHelperRegular helperRegular = INotifyHelperRegular(notifyHelperRegular);
    IFeeRewardForwarder feeRewardForwarder = IFeeRewardForwarder(helperRegular.feeRewardForwarder());
    require(amounts.length == pools.length, "Amounts and pools lengths mismatch");
    for (uint i = 0; i < pools.length; i++) {
      alreadyNotified[pools[i]] = false;
    }

    uint256 check = 0;
    for (uint i = 0; i < pools.length; i++) {
      require(amounts[i] > 0, "Notify zero");
      require(!alreadyNotified[pools[i]], "Duplicate pool");

      IERC20(farm).safeTransferFrom(msg.sender, address(this), amounts[i]);
      IERC20(farm).safeApprove(address(feeRewardForwarder), 0);
      IERC20(farm).safeApprove(address(feeRewardForwarder), amounts[i]);
      feeRewardForwarder.notifyIFarmBuybackAmount(farm, pools[i], amounts[i]);
      mostRecentWeeklyFarm[pools[i]] = amounts[i];
      mostRecentWeeklyFarmTime[pools[i]] = block.timestamp;

      check = check.add(amounts[i]);
      alreadyNotified[pools[i]] = true;
    }
    require(sum == check, "Wrong check sum");
  }
}
