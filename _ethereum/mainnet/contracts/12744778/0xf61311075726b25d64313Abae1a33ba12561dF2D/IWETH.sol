pragma solidity 0.6.12;
interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}