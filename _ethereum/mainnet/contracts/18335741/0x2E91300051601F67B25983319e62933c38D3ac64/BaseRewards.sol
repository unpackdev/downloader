// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./BaseFees.sol";
import "./CoreRewards.sol";
import "./ReentrancyGuard.sol";
import "./DefinitiveAssets.sol";

abstract contract BaseRewards is BaseFees, CoreRewards, ReentrancyGuard {
    using DefinitiveAssets for IERC20;

    function claimAllRewards(
        uint256 feePct
    )
        external
        override
        onlyWhitelisted
        nonReentrant
        stopGuarded
        returns (IERC20[] memory rewardTokens, uint256[] memory earnedAmounts)
    {
        (rewardTokens, earnedAmounts) = _claimAllRewards();
        uint256 rewardTokensLength = rewardTokens.length;
        uint256[] memory feeAmounts = new uint256[](rewardTokensLength);
        if (FEE_ACCOUNT != address(0) && feePct > 0) {
            for (uint256 i; i < rewardTokensLength; ) {
                if (earnedAmounts[i] == 0) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
                feeAmounts[i] = _handleFeesOnAmount(address(rewardTokens[i]), earnedAmounts[i], feePct);
                unchecked {
                    ++i;
                }
            }
        }
        emit RewardsClaimed(rewardTokens, earnedAmounts, feeAmounts);
    }
}
