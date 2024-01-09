// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface ILPCalculator {
    function valuationUSD( address _token, uint _amount ) external view returns ( uint );
}