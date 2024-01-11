// contracts/AMYToken.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract AMYToken is ERC20, ERC20Burnable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply * 10**decimals());
    }
}
