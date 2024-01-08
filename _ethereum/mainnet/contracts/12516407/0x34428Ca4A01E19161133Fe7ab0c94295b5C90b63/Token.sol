pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Mikker", "MIKKER") {
        _mint(msg.sender, 300);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}

