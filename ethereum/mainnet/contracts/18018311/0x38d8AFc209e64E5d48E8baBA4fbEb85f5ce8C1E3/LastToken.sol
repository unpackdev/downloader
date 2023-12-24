// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract LastToken is ERC20 {
    constructor(address _tokenVault) ERC20("LastToken", "LTK") {
        _mint(_tokenVault, 1000000 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
