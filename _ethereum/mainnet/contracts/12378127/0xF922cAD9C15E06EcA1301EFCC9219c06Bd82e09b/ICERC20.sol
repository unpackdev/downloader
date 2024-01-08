// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICERC20 {
    function mint(uint) external returns (uint);
    function redeem(uint) external returns (uint);
    function transfer(address dst, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function supplyRatePerBlock() external returns (uint);
    function approve(address spender, uint amount) external returns (bool);
}
