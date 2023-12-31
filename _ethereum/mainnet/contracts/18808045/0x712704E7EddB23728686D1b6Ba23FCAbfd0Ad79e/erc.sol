// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract GoerliEthscription is ERC20 {
    constructor() ERC20("Goerli Ethscription", "GORS") {
      _mint(msg.sender, 1 * 10 ** decimals());
    }
}
