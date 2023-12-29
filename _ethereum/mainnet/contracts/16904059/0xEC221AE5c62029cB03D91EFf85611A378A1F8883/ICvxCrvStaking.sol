// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICvxCrvStaking {
    struct EarnedData {
        address token;
        uint256 amount;
    }

    function balanceOf(address) external view returns (uint256);

    function getReward(address _account) external;

    function getReward(address _account, address _forwardTo) external;

    function rewardSupply(uint256 _rewardGroup) external view returns (uint256);

    function earned(address _account) external returns (EarnedData[] memory);

    function setRewardWeight(uint256 _weight) external;

    function userRewardBalance(address _address, uint256 _rewardGroup)
        external
        view
        returns (uint256);

    function rewardLength() external view returns (uint256);

    function stake(uint256 _amount, address _to) external;

    function stakeFor(address _to, uint256 _amount) external;

    function withdraw(uint256 _amount) external;
}
