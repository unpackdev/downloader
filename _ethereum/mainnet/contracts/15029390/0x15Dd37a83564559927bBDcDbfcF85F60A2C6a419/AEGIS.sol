// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract AegisToken is ERC20, ERC20Burnable, Pausable, Ownable {
    uint256 private TOTAL_SUPPLY = 1100 * (10 ** 6); // 1.1 billion
    constructor() ERC20("Aegis Token", "AEGIS") {
        uint256 dec = 10 ** decimals();
        _mint(payable(msg.sender), TOTAL_SUPPLY * dec);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    virtual
    override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
