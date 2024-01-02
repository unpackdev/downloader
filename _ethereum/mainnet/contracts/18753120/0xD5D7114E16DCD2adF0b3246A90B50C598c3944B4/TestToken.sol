// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable2Step.sol";

contract TestToken is ERC20, Ownable2Step {
    constructor(address _owner, string memory name, string memory symbol) ERC20(name, symbol) Ownable(_owner) { }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}
