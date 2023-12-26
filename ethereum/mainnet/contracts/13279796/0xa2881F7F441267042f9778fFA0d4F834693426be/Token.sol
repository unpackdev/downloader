pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC20.sol";

contract Token is Context, ERC20 {
    constructor(string memory tokenName, string memory tokenSymbol, uint256 amount)
        public
        ERC20(tokenName, tokenSymbol)
    {
        _mint(_msgSender(), amount);
    }
}
