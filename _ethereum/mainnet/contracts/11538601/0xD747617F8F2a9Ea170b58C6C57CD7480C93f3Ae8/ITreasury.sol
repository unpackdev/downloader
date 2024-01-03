pragma solidity ^0.7.3;

interface ITreasury {

    function userDeposit(address user, uint256 amount) external;
    function userWithdraw(address user, uint256 amount) external;
    function collectFromUser(address user, uint256 amount) external;
    function payToUser(address user, uint256 amount) external;
    
    function getUserBalance(address user) external view returns (uint256);

}