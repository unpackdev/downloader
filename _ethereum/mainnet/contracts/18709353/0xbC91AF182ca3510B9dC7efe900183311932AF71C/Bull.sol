// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Base.sol";

contract Bull is ERC20Base {
      constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol
    )
        ERC20Base(
            _defaultAdmin,
            _name,
            _symbol
        ) {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}