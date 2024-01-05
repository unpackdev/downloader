// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";


contract ProtToken is ERC20, ERC20Burnable, ERC20Pausable {
    constructor(uint256 initialSupply) public ERC20("ProStarter", "PROT") {
        _mint(msg.sender, initialSupply);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}