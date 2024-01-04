pragma solidity ^0.5.16;

interface IWeth {
    function deposit() external payable;
    function withdraw(uint wad) external;
}