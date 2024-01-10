// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRewardDistributor {

    function addRecipient(address _recipient) external;
    function removeRecipient(address _recipient) external;

    function setRecipientRewardRate(address _recipient, uint256 _rewardRate) external;
    function addRecipientAndSetRewardRate(address _recipient, uint256 _rewardRate) external;

    function rescueStakingPoolTokens(
        address _stakingPool,
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function rewardToken() external view returns (address);

    function getAllRecipients() external view returns (address[] memory _allRecipients);
}
