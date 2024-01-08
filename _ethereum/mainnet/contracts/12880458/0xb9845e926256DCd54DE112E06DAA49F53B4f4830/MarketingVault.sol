//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DesignedVault.sol";

contract MarketingVault is DesignedVault {
    constructor(address _tosAddress, uint256 _maxInputOnce)
        DesignedVault("Marketing Fund", _tosAddress, _maxInputOnce)
    {}
}
