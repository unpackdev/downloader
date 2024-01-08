// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenGamesLock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Games";
        maxCap = 10000000 ether;
        numberLockedMonths = 2; 
        numberUnlockingMonths = 20;
        unlockPerMonth = 500000 ether;
    }

}