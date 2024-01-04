pragma solidity 0.7.1;

interface ICurly {
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
}