// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


interface ILGE {
    event LiquidityEventStarted(address _address);
    event LiquidityCapReached(address _address);
    event LiquidityEventCompleted(address _address, uint256 totalContributors, uint256 totalContributed);
    event UserContributed(address indexed _address, uint256 _amount);
    event UserClaimed(address indexed _address, uint256 _amount);

    function active() external view returns (bool);
    function eventStartTimestamp() external view returns (uint256);
    function eventEndTimestamp() external view returns (uint256);
    function totalContributors() external view returns (uint256);
    function totalEthContributed() external view returns (uint256);
    function tokenDistributionRate() external view returns (uint256);
    function goldBoardsReserved() external view returns (uint256);
    function silverBoardsReserved() external view returns (uint256);

    function activate() external;
    function contribute() external payable;
    function startEvent() external;
    function claim() external;
    function retrieveLeftovers() external;

    function getContribution(address _address) external view returns (uint256 amount, uint256 board);
}