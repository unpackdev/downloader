pragma solidity 0.6.12;

interface IStakeGatling {

    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function presentRate() external view returns (uint256);
    function profitRateDenominator() external view returns (uint256);
    function totalToken() external view returns (uint256 amount0, uint256 amount1);

}