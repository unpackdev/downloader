// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";


contract Basket is ERC20Permit, ERC20Burnable, Ownable {
    constructor(address _owner) public ERC20("Baskets.Finance", "BASKET") EIP712("Baskets.Finance", "1") {
        _mint(_owner, 1e8 ether);
        transferOwnership(_owner);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
