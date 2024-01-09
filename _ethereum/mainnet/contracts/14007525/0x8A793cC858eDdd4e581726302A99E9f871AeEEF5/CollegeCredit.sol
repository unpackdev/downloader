pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./ICollegeCredit.sol";

contract CollegeCredit is ERC20, Ownable, ICollegeCredit {
    constructor() ERC20("College Credit", "CREDIT") {}
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function mint(address recipient, uint256 amount) override external onlyOwner {
        _mint(recipient, amount);
    }
}