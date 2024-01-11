pragma solidity ^0.7.6;

interface IDC  {
    function instaMint(address token, uint256 incomingTokenAmount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}
