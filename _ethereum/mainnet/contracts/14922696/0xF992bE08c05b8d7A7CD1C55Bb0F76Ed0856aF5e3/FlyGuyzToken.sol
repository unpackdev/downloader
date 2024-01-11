// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract FlyGuyzToken is
    Context,
    ERC20,
    Ownable //ERC20,
{
    uint256 public INITIAL_SUPPLY = 800000000 * (10**uint256(decimals()));

    constructor(address ownerShip) ERC20("FlyGuyz", "Flyy") {
        _mint(ownerShip, INITIAL_SUPPLY);
        transferOwnership(ownerShip);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), (amount * (10**uint256(decimals()))));
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), (amount * (10**uint256(decimals()))));
    }
}
