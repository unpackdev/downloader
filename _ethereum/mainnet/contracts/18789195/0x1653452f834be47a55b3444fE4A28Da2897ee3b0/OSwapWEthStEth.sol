// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./OSwapBase.sol";
import "./LiquidityManagerStEth.sol";

contract OSwapWEthStEth is OSwapBase, LiquidityManagerStEth {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    constructor() OSwapBase(WETH, STETH) {}
}
