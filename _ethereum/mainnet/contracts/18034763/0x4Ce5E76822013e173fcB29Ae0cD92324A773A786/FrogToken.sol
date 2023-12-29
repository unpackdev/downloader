// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol";
import "./Ownable.sol";

contract FROG is ERC20, Ownable 
{
    constructor() ERC20("Trippie Frog", "FROG") 
    {
        _mint(msg.sender, 10000000 * (10 ** decimals()));
    }

    function decimals() public view virtual override returns (uint8) 
    {
        return 0;
    }
}
