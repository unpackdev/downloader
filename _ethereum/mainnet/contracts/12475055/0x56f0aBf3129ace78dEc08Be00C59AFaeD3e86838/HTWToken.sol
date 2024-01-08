// HTWToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC777.sol";
import "./Ownable.sol";


contract HTWToken is ERC777, Ownable {
    constructor() 
    ERC777("Heal The World Coin", "HTW", new address[](0))
    Ownable()
    {
        uint initialSupply = (1*1000*1000*1000) * 10 ** 18;
        _mint(msg.sender, initialSupply, "", "");
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount, "", "");
    }
}