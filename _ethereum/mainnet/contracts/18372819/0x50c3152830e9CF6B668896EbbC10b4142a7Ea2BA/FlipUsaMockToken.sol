// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";

contract FlipUsaMockToken is ERC20 {
    event Mint(address to, uint256 amount);
    event Burn(address to, uint256 amount);

    uint8 public immutable decimalsOf;
    address public immutable minter;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        decimalsOf = 18;
        minter = msg.sender;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimalsOf;
    }

    function mint(address account, uint256 _amount) public {
        require(msg.sender == minter, "ERC20Mock: only minter can mint");
        _mint(account, _amount);
    }

    function burn(address account, uint256 _amount) public {
        require(msg.sender == minter, "ERC20Mock: only minter can mint");
        _burn(account, _amount);
    }
}
