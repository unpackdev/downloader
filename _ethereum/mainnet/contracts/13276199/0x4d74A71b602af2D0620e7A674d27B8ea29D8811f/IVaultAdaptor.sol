pragma solidity 0.8.4;

import "./IERC20.sol";

interface IVaultAdaptor {
    function underlying() external view returns (IERC20);
    function totalValue() external view returns (uint256);
    function totalDeposited() external view returns (uint256);
    function harvest(address rewards) external;
    function deposit(uint256 _amount) external;
}