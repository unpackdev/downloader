// contracts/OGMaverixToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// IMPORTED From Locally Stored Files
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";

// (OGX) - OGMaverix Token Contract
contract OGMaverix is ERC20, ERC20Capped, ERC20Burnable, Pausable, Ownable {
    // CREATE - Initial Supply
    constructor(
        uint256 cap
    ) ERC20("OGMaverix", "OGX") ERC20Capped(cap * (10 ** decimals())) {
        _mint(msg.sender, 4000000000 * (10 ** decimals()));
    }

    // SET - Capped Supply
    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20Capped, ERC20) {
        require(
            ERC20.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    // SECURITY - PAUSE/UNPAUSE CONTRACT
    function Pause() public onlyOwner {
        _pause();
    }

    function Unpause() public onlyOwner {
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
