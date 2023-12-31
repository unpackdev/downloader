// SPDX-License-Identifier: MIT
// XEN Contracts v0.6.0
pragma solidity ^0.8.1;

contract _CReentrancyGuards {
    bool        private                 _bGuard;
    modifier noReentrancy() {
        require( !_bGuard, "Reentrant call" );
        _bGuard = true;
        _;
        _bGuard = false;
    }
}