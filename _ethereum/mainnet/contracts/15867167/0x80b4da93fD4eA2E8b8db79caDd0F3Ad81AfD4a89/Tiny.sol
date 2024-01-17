// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// External references
import "./ERC20.sol";

contract Tiny is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply
    ) ERC20(_name, _symbol, _decimals) {
       _mint(msg.sender, initialSupply);
    }

    function hi() public pure returns (string memory) {
        return "world";
    }
}
