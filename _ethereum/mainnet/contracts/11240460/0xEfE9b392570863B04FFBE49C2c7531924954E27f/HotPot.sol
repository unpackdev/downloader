pragma solidity ^0.6.0;

import "./ERC20.sol";

contract HotPot is ERC20 {
    constructor() public ERC20("HotPot Token", "HotPot") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
