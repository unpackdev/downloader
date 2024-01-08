//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DesignedVault.sol";

contract InitialContributorVault is DesignedVault {
    constructor(address _tosAddress, uint256 _maxInputOnce)
        DesignedVault("InitialContributor", _tosAddress, _maxInputOnce)
    {}
}
