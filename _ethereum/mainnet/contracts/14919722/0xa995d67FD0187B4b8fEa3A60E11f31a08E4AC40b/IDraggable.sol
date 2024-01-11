// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
interface IDraggable {
    
    function oracle() external view returns (address);
    function drag(address buyer, IERC20 currency) external;
    function notifyOfferEnded() external;
    function votingPower(address voter) external returns (uint256);
    function totalVotingTokens() external view returns (uint256);
    function notifyVoted(address voter) external;

}