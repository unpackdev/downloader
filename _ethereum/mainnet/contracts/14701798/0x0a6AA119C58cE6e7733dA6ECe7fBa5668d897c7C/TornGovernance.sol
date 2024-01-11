pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ITornStaking.sol";

contract TornGovernance {
  using SafeMath for uint256;

  event RewardUpdateSuccessful(address indexed account);
  event RewardUpdateFailed(address indexed account, bytes indexed errorData);

  /// @notice Locked token balance for each account
  mapping(address => uint256) public lockedBalance;

  IERC20 public torn;
  ITornStaking public Staking;

  modifier updateRewards(address account) {
    try Staking.updateRewardsOnLockedBalanceChange(account, lockedBalance[account]) {
      emit RewardUpdateSuccessful(account);
    } catch (bytes memory errorData) {
      emit RewardUpdateFailed(account, errorData);
    }
    _;
  }

  constructor(address _torn) public {
    torn = IERC20(_torn);
  }

  function setStaking(address staking) public virtual {
    Staking = ITornStaking(staking);
  }

  function lockWithApproval(uint256 amount) public virtual updateRewards(msg.sender) {
    require(torn.transferFrom(msg.sender, address(this), amount), "TORN: transferFrom failed");
    lockedBalance[msg.sender] = lockedBalance[msg.sender].add(amount);
  }

  function unlock(uint256 amount) public virtual updateRewards(msg.sender) {
    //    require(getBlockTimestamp() > canWithdrawAfter[msg.sender], "Governance: tokens are locked");
    lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(amount, "Governance: insufficient balance");
    require(torn.transfer(msg.sender, amount), "TORN: transfer failed");
  }
}
