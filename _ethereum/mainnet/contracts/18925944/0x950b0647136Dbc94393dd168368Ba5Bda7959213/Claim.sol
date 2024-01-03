// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./VestedClaim.sol";

contract Claim is VestedClaim {
    event ClaimantsAdded(
        address[] indexed claimants,
        uint256[] indexed amounts
    );

    event RewardsFrozen(address[] indexed claimants);

    constructor(uint256 _claimTime, address _token) VestedClaim(_token) {
        claimTime = _claimTime;
    }

    function updateClaimTimestamp(uint256 _claimTime) external onlyOwner {
        claimTime = _claimTime;
    }

    function addClaimants(
        address[] calldata _claimants,
        uint256[] calldata _claimAmounts
    ) external onlyOwner {
        require(
            _claimants.length == _claimAmounts.length,
            "Arrays do not have equal length"
        );

        for (uint256 i = 0; i < _claimants.length; i++) {
            setUserReward(_claimants[i], _claimAmounts[i]);
        }

        emit ClaimantsAdded(_claimants, _claimAmounts);
    }

    function freezeRewards(address[] memory _claimants) external onlyOwner {
        for (uint256 i = 0; i < _claimants.length; i++) {
            freezeUserReward(_claimants[i]);
        }

        emit RewardsFrozen(_claimants);
    }

    // set user info for multiple users
    function setUserInfo(
        address[] calldata _users,
        uint256[] calldata _rewards,
        uint256[] calldata _withdrawns
    ) external onlyOwner {
        require(
            _users.length == _rewards.length &&
                _users.length == _withdrawns.length,
            "Arrays do not have equal length"
        );

        for (uint256 i = 0; i < _users.length; i++) {
            _setUserInfo(_users[i], _rewards[i], _withdrawns[i]);
        }

        emit ClaimantsAdded(_users, _rewards);
    }

    function _setUserInfo(
        address _user,
        uint256 _reward,
        uint256 _withdrawn
    ) internal {
        UserInfo storage user = userInfo[_user];

        user.reward = _reward;
        user.withdrawn = _withdrawn;

        totalRewards += _reward;
        totalWithdrawn += _withdrawn;

        require(user.reward >= user.withdrawn, "Invalid reward amount");
    }
}
