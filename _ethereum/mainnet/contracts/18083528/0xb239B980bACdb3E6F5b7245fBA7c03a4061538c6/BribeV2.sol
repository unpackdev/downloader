// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IBribeRewarderFactory.sol";
import "./IBribe.sol";
import "./IVoter.sol";
import "./MultiRewarderPerSecV2.sol";

/**
 * Simple bribe per sec. Distribute bribe rewards to voters
 * Bribe.onVote->updateReward() is a bit different from SimpleRewarder.
 * Here we reduce the original total amount of share
 */
contract BribeV2 is IBribe, MultiRewarderPerSecV2 {
    using SafeERC20 for IERC20;

    function onVote(
        address _user,
        uint256 _newVote,
        uint256 _originalTotalVotes
    ) external override onlyMaster nonReentrant returns (uint256[] memory rewards) {
        _updateReward(_originalTotalVotes);
        return _onReward(_user, _newVote);
    }

    function onReward(address, uint256) external override onlyMaster nonReentrant returns (uint256[] memory) {
        revert('Call BribeV2.onVote instead');
    }

    function _getTotalShare() internal view override returns (uint256 voteWeight) {
        (, voteWeight) = IVoter(master).weights(lpToken);
    }

    function rewardLength() public view override(IBribe, MultiRewarderPerSecV2) returns (uint256) {
        return MultiRewarderPerSecV2.rewardLength();
    }

    function rewardTokens() public view override(IBribe, MultiRewarderPerSecV2) returns (IERC20[] memory tokens) {
        return MultiRewarderPerSecV2.rewardTokens();
    }

    function pendingTokens(
        address _user
    ) public view override(IBribe, MultiRewarderPerSecV2) returns (uint256[] memory tokens) {
        return MultiRewarderPerSecV2.pendingTokens(_user);
    }
}
