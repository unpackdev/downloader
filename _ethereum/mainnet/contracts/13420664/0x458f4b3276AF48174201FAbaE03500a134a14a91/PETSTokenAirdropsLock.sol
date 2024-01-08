// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenAirdropsLock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Airdrops";
        maxCap = 3200000 ether;
        numberLockedMonths = 1; 
        numberUnlockingMonths = 2;
        unlockPerMonth = 1600000 ether;
    }

}