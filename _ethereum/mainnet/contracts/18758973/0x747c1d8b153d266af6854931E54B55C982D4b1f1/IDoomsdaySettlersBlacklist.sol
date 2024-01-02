// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

interface IDoomsdaySettlersBlacklist {
    function checkBlocked(address _addr) external view returns(bool);
}