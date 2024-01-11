// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20Votes.sol";
import "./Ownable.sol";

contract SomeEXP is Ownable, ERC20Votes {
    constructor(address daoReserveAddress, address stakingPoolAddress)
        ERC20("SomeEXP", "EXP")
        ERC20Permit("SomeEXP")
    {
        uint256 factor = 10**decimals();
        _mint(daoReserveAddress, 8e11 * factor);
        _mint(stakingPoolAddress, 2e11 * factor);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
