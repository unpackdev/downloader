pragma solidity ^0.8.0;

interface IABCTreasury {
    function sendABCToken(address recipient, uint _amount) external;

    function updateUserPoints(address _user, uint _amountGained, uint _amountLost) external;

    function tokensClaimed() external view returns(uint);
    
    function updateNftPriced() external;
    
    function updateProfitGenerated(uint _amount) external;

    function getAuction() view external returns(address);
}