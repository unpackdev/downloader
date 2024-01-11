// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Global_Recession_Token is ERC20 {
    //85% Copper launch(15% burned before adding liquidity to uniswap)
    //15% Dev
    constructor() ERC20("Global Recession Token", "GRT") {
        _mint(msg.sender, 10000000000 * 1e18);
    }
}