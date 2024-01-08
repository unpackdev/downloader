pragma solidity 0.6.12;

import "./ERC20.sol";

contract USDT is ERC20 {
    string private constant _name = "Tether USD";
    string private constant _symbol = "USDT";
    uint256 private constant _cap = 1e24;

    constructor() public ERC20(_name, _symbol) {
        _mint(msg.sender, _cap);
    }
}
