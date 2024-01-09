// SPDX-License-Identifier: MIT

/*

██╗ ██████╗ ███╗   ██╗
██║██╔═══██╗████╗  ██║
██║██║   ██║██╔██╗ ██║
██║██║   ██║██║╚██╗██║
██║╚██████╔╝██║ ╚████║
╚═╝ ╚═════╝ ╚═╝  ╚═══╝


ION Utility Token Contract for The Humanoids Eco-System

*/

pragma solidity =0.8.11;

import "./ERC20Burnable.sol";

import "./OwnableTokenAccessControl.sol";

contract ION is ERC20Burnable, OwnableTokenAccessControl {

    constructor() ERC20("ION Token", "ION") {
        _mint(msg.sender, 250_000 ether);
    }

    function mint(address to, uint256 amount) external {
        require(_hasAccess(Access.Mint, _msgSender()), "Not allowed to mint");
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        if (_hasAccess(Access.Burn, _msgSender())) {
            _burn(account, amount);
        }
        else {
            super.burnFrom(account, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (_hasAccess(Access.Transfer, _msgSender())) {
            _transfer(sender, recipient, amount);
            return true;
        }
        return super.transferFrom(sender, recipient, amount);
    }
}
