// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./EIP20Interface.sol";

interface MTokenInterface {
    /*** User contract ***/
    function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function getCash() external view returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
    function getUnderlying() external view returns(address);
    function sweepToken(EIP20Interface token) external;


    /*** Admin Functions ***/
    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
}