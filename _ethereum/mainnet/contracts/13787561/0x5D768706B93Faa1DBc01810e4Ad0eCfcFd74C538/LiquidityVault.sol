//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./OnthersVault.sol";

contract LiquidityVault is OnthersVault {
    constructor(address _tokenAddress)
        OnthersVault("Liquidity", _tokenAddress)
    {}
}
