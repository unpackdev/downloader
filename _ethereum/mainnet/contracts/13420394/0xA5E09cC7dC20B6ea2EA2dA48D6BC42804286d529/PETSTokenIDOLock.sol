// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenIDOLock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "IDO";
        maxCap = 1050000 ether;
        numberLockedMonths = 0; 
        numberUnlockingMonths = 3;
        unlockPerMonth = 350000 ether;
    }

}