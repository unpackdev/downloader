// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface ISPV {
    function SPVWallet() external view returns ( address );

    function totalValue() external view returns ( uint );

    function totalProfit() external view returns ( uint );
}