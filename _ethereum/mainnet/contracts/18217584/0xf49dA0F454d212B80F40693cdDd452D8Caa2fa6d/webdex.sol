// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ERC20FlashMint.sol";

// Whitepaper: https://web-dex.gitbook.io/web-dex-white-paper/
/// @custom:security-contact web.dex.io@proton.me
contract webdex is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    Ownable,
    Pausable,
    ERC20Permit,
    ERC20Votes,
    ERC20FlashMint
{
    constructor() ERC20("WEbdEX", "WEbdEX") ERC20Permit("WEbdEX") {
        _mint(msg.sender, 369369369 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
