// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract Nuts is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Nuts", "NUTS")
        Ownable(initialOwner)
    {
        _mint(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045, 1 * 10 ** decimals());
        _mint(initialOwner, 3 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
