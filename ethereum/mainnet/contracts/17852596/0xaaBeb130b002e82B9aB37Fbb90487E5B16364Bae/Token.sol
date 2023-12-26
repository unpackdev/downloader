// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./ERC20.sol";

contract Token is ERC20 {
    address public nameSetter = msg.sender;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol, 18) {
        _mint(msg.sender, _totalSupply);
    }

    function setName(string memory _name, string memory _symbol) public {
        require(msg.sender == nameSetter, "Only name setter");
        name = _name;
        symbol = _symbol;
    }
}
