// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface ICToken {
    function transfer(address dst, uint256 amount) external returns (bool);

    function mint(uint256 mintAmount) external returns (uint256);

    //function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);

    //function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    //function balanceOfUnderlying(address owner) external returns (uint);
    //function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    //function borrowRatePerBlock() external view returns (uint);
    //function supplyRatePerBlock() external view returns (uint);
    //function totalBorrowsCurrent() external returns (uint);
    //function borrowBalanceCurrent(address account) external returns (uint);
    //function borrowBalanceStored(address account) public view returns (uint);
    //function exchangeRateCurrent() public returns (uint);
    //function exchangeRateStored() public view returns (uint);
    //function getCash() external view returns (uint);
    //function accrueInterest() public returns (uint);
    //function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
}
