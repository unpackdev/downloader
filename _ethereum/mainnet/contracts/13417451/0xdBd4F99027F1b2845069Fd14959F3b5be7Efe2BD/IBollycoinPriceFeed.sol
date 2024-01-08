pragma solidity >=0.6.0;

interface IBollycoinPriceFeed {
     
    function getLatestETHPrice() external view returns(uint256);
    function getLatestBTCPrice() external view returns(uint256);

 
}