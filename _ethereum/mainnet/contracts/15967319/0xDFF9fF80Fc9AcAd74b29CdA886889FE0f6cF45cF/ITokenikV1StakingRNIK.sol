// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface ITokenikV1StakingRNIK {

    event StakeRNIK(address indexed user, uint);
    event UnstakeRNIK(address indexed user, uint);

    function rewards() external view returns(address);
    function stakingApy() external view returns(uint256);
    function apySetter() external view returns(address);
    function minStakeDuration() external view returns(uint256);
    function stakingOpen() external view returns(bool);
    function stakingCloseDate() external view returns(uint256);
    function totalStaked() external view returns(uint256);
    function stakeRNIK(uint256 _amount) external;
    function unstakeRNIK() external;
    function getInterest(address _account) external view returns(uint256);
    function getUserStake(address _account) external view returns(uint256, uint256); 
    function setRewardsAddress(address _address) external;
    function setApySetter(address _address) external;
    function setStakingApy(uint256 _stakingApy) external;
    function setMinStakeDuration(uint256 _minStakeDuration) external;
    function setStakingOpen(bool _stakingOpen) external;
    function setStakingCloseDate(uint256 _stakingCloseDate) external;
}