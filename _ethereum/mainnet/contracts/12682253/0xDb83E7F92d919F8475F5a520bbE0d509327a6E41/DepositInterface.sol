// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

interface DepositInterface {
	function unlockVestedDeposit() external returns (uint256 numTokens);
	function deposit(uint nDays) external returns(uint256 newTokensToMint);
}

interface PoolInterface {
    function nTokens() external view returns (uint);
    function tokenAt(uint i) external view returns (address);
}