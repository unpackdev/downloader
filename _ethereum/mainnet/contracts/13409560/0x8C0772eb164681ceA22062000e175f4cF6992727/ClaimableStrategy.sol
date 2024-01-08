pragma solidity ^0.6.0;

import "./BaseStrategy.sol";
import "./IVaultStakingRewards.sol";

abstract contract ClaimableStrategy is BaseStrategy {
    event ClaimedReward(address rewardToken, uint256 amount);

    function claim(address _rewardToken)
        external
        override
        onlyControllerOrVault
        returns (bool)
    {
        address _vault = IController(controller).vaults(_want);
        require(_vault != address(0), "!vault 0");
        IERC20 token = IERC20(_rewardToken);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.safeTransfer(_vault, amount);
            IVaultStakingRewards(_vault).notifyRewardAmount(
                _rewardToken,
                amount
            );
            emit ClaimedReward(_rewardToken, amount);
            return true;
        }
        return false;
    }
}
