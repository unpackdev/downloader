pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./IROOLAH.sol";

contract ROOLAH is ERC20, Ownable, IROOLAH {
    constructor() ERC20("ROOLAH", "ROOLAH") {}
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }
}