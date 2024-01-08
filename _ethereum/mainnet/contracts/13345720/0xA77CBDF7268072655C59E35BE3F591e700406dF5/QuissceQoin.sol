pragma solidity ^0.8.5;

import "./ERC20.sol";
import "./ERC20Capped.sol";

contract QuissceQoin is ERC20, ERC20Capped {
    address public admin;

    constructor() ERC20("Quissce Qoin", "QWIS") ERC20Capped(69_000_000e18) {
        admin = msg.sender;
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        return super._mint(account, amount);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "only admin");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
