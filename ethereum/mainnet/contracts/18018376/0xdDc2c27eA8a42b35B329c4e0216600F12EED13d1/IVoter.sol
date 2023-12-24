// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./IERC20.sol";

import "./IBribe.sol";

interface IGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IVoter {
    struct GaugeWeight {
        uint128 allocPoint;
        uint128 voteWeight; // total amount of votes for an LP-token
    }

    function infos(
        IERC20 _lpToken
    )
        external
        view
        returns (
            uint104 supplyBaseIndex,
            uint104 supplyVoteIndex,
            uint40 nextEpochStartTime,
            uint128 claimable,
            bool whitelist,
            IGauge gaugeManager,
            IBribe bribe
        );

    // lpToken => weight, equals to sum of votes for a LP token
    function weights(IERC20 _lpToken) external view returns (uint128 allocPoint, uint128 voteWeight);

    // user address => lpToken => votes
    function votes(address _user, IERC20 _lpToken) external view returns (uint256);

    function setBribe(IERC20 _lpToken, IBribe _bribe) external;

    function distribute(IERC20 _lpToken) external;
}
