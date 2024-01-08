// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenMarketingAndPartnershipsLock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Marketing And Partnerships";
        maxCap = 7600000 ether;
        numberLockedMonths = 0; 
        numberUnlockingMonths = 19;
        unlockPerMonth = 400000 ether;
    }

}