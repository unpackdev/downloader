// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreRewardsV1.sol";
import "./Context.sol";
import "./DefinitiveAssets.sol";

abstract contract CoreRewards is ICoreRewardsV1, Context {
    /**
     * @dev Override this method for the implementation of returning tokens and their respective claim amounts
     *
     * @notice returns the reward token and amount of unclaimed tokens
     * @return (IERC20[], uint256[])    tokens and rewards
     */
    function unclaimedRewards() public view virtual returns (IERC20[] memory, uint256[] memory);

    function claimAllRewards(uint256 feePct) external virtual returns (IERC20[] memory, uint256[] memory);

    /**
     * @dev Override this method for the implementation of claiming rewards
     */
    function _claimAllRewards() internal virtual returns (IERC20[] memory, uint256[] memory);
}
