// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";


contract THESE is ERC20, Ownable {
    address private _hatDAO = 0x15f4d11dD90382F7FD81D0ca37D5D7e44706ffCE;
    address private _team = 0x80319b22FC81D700485B915FEE3d2D9C69DC3839;

    constructor() ERC20("THESE", "THESE") {
        _mint(_hatDAO, 100000 * 10 ** decimals());
        _mint(_team, 1000 * 10 ** decimals());
        transferOwnership(_hatDAO);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
