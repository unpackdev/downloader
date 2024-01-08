pragma solidity 0.6.6;

interface IEglGenesis {
    function owner() external view returns(address);
    function cumulativeBalance() external view returns(uint);
    function canContribute() external view returns(bool);
    function canWithdraw() external view returns(bool);
    function contributors(address contributor) external view returns(uint, uint, uint, uint);
}