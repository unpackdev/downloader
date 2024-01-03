pragma solidity 0.6.6;

import "./TREERewards.sol";
import "./CloneFactory.sol";

contract TREERewardsFactory is CloneFactory {
  address public immutable template;

  event CreateRewards(address _rewards);

  constructor(address _template) public {
    template = _template;
  }

  function createRewards(
    uint256 _starttime,
    address _stakeToken,
    address _rewardToken
  ) external returns (TREERewards) {
    TREERewards rewards = TREERewards(createClone(template));
    rewards.init(msg.sender, _starttime, _stakeToken, _rewardToken);
    emit CreateRewards(address(rewards));
    return rewards;
  }
}
