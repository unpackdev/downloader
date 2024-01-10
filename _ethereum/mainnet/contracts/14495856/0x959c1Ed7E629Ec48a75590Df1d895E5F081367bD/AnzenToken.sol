// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

contract AnzenToken is Context, Ownable, ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        _mint(_msgSender(), _initialSupply);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        // Burn only own tokens
        _burn(_msgSender(), amount); 
    }
}
