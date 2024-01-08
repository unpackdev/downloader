//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DesignedVault.sol";

contract LPStakingVault is DesignedVault {
    constructor(address _docAddress)
        DesignedVault("LPStaking", _docAddress)
    {}
}
