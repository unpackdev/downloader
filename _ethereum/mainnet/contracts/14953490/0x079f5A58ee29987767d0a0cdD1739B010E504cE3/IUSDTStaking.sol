// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUSDTStaking {
    function SetPlan(uint256 _planIndex, uint256 _earn, uint256 _duration) external;
    function GetInfoPlan(uint256 _planIndex) view external returns(uint256, uint256);
    function SetInfoStaking (uint256[] calldata _tokenIdArr, uint256 _planIndex) external;
    function GetInfoStaking(address _account, uint256 _tokenId) view external returns (uint256, uint256, uint256, uint256);
    function Claim(uint256 _stakingIndex) external;
    function RetrieveToken() external returns (uint256);
    function ERC20TokenBalance() external returns (uint256);

    event PlanCreated(uint256 _earn, uint256 _duration, uint256 _planIndex );
    event Staked(address account);
    event Claimed(address account);
}