pragma solidity 0.8.10;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Orbital", "ORBZ") {
        _mint(msg.sender, 1_300_000_000 * 10**18);
    }
}
