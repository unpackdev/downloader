pragma solidity >=0.6.0 <0.7.0;

interface BarnRewardsInterface {
    function claim() external;
    function owed(address _address) external view returns (uint256);
    function registerUserAction(address _user) external;
    function currentMultiplier() external view returns (uint256);
    function userMultiplier(address _user) external view returns (uint256);
}