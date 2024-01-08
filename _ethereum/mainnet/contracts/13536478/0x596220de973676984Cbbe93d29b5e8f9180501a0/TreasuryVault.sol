//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DesignedVault.sol";

contract TreasuryVault is DesignedVault {
    constructor(address _docAddress)
        DesignedVault("Treasury", _docAddress)
    {}
}
