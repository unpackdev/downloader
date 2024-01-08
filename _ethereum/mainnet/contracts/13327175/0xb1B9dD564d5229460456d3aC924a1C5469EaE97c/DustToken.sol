//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC777.sol";
import "./Ownable.sol";

contract DustToken is ERC777, Ownable {

    constructor(
        string memory name,
        string memory symbol,
        address[] memory _defaultOperators,
        uint256 _initialSupply
    )
    ERC777(name, symbol, _defaultOperators) {
        _mint(msg.sender, _initialSupply, "", "");
    }

}