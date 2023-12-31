// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ERC20FlashMint.sol";

// @custom:security-contact trusted@ozagold.com
contract Ozacoin is
    ERC20,
    Pausable,
    Ownable,
    ERC20Permit,
    ERC20Votes,
    ERC20FlashMint
{
    /**
     * @notice Construct a new Ozacoin token
     */
    constructor() ERC20("Ozacoin", "OZA") ERC20Permit("Ozacoin") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

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

    // The following functions are overrides required by Solidity.

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
