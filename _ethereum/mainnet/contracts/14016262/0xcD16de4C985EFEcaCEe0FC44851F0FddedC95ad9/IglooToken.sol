// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20.sol";

contract IglooToken is Ownable, Pausable, ERC20("IGLOO", "IG") {
    constructor() {
        _mint(msg.sender, 1 * 1e9 * 1e18); // 1 Billion Supply = 1 * 9 zeros * 18 zeros
    }

    // minting
    bool public mintStopped = false;

    function mint(address account, uint256 amount) public onlyOwner {
        require(!mintStopped, "mint is stopped");
        _mint(account, amount);
    }

    function stopMint() public onlyOwner {
        mintStopped = true;
    }

    // white list
    mapping(address => bool) private whitelist;

    function setWhitelist(address[] calldata minters) external onlyOwner {
        for (uint256 i; i < minters.length; i++) whitelist[minters[i]] = true;
    }

    function whitelist_mint(address account, uint256 amount) external {
        require(whitelist[msg.sender], "ERC20: sender must be whitelisted");
        _mint(account, amount);
    }

    // ERC20Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
