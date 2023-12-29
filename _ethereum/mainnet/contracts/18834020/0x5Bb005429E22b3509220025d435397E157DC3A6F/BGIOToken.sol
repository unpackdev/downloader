// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract BGIOToken is ERC20, ERC20Capped, Pausable, Ownable {
    constructor()
        ERC20("BIGAME", "BGIO")
        ERC20Capped(210_000_000_000 * 10 ** decimals())
    {
        _mint(msg.sender, 50_000_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _mint(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Capped) {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0)) {
            _requireNotPaused();
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
