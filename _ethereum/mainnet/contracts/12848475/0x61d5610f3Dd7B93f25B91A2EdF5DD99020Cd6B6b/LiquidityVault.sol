//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DesignedVault.sol";

contract LiquidityVault is DesignedVault {
    constructor(address _tosAddress, uint256 _maxInputOnce)
        DesignedVault("Liquidity", _tosAddress, _maxInputOnce)
    {}
}
