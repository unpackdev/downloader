pragma solidity ^0.6.0;

import "./BaseStrategy.sol";
import "./IVaultStakingRewards.sol";

abstract contract ClaimableStrategy is BaseStrategy {
    event ClaimedReward(address rewardToken, uint256 reward);

    function claim(address _rewardToken)
        external
        override
        onlyControllerOrVault
    {
        address _vault = IController(controller).vaults(_want);
        require(_vault != address(0), "!vault 0");
        IERC20 token = IERC20(_rewardToken);
        uint256 reward = token.balanceOf(address(this));
        if (reward > 0) {
            token.safeTransfer(_vault, reward);
            IVaultStakingRewards(_vault).notifyRewardAmount(
                _rewardToken,
                reward
            );
            emit ClaimedReward(_rewardToken, reward);
        }
    }
}
