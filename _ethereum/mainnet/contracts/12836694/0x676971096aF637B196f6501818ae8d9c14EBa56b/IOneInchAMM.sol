pragma solidity 0.7.6;


interface IOneInchAMM {
    function swap(address src, address dst, uint256 amount, uint256 minReturn, address referral) external payable returns(uint256 result);
}