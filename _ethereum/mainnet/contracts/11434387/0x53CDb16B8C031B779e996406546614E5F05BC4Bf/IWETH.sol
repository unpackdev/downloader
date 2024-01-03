pragma solidity 0.6.12;

interface IWETH {
    function withdraw(uint256 wad) external;
    function deposit() external payable;
}