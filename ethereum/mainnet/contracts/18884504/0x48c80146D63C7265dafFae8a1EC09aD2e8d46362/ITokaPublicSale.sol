pragma solidity =0.8.21;

interface ITokaPublicSale{
    function totalRollover() external view returns (uint256);
    function userRollover(address) external view returns (uint256);
}