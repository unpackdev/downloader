pragma solidity >=0.5.0 <0.7.0;

interface IYieldsterStrategy {
    
    function tokenValueInUSD() external view returns(uint256);

}
