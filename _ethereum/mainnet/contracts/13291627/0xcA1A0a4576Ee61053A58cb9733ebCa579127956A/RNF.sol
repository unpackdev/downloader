// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract RNF is ERC20, Ownable{
    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }
    function burn(uint256 amount) public {
        _burn(msg.sender,amount);
    }
    constructor() ERC20("Rainbow NFT Investment Fund Token", "RNF")  {

    }
}
