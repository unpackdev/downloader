// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./draft-ERC20Permit.sol";
import "./SafeMath.sol";

contract SpaceClubCoin is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ERC20Permit {
    constructor() ERC20("Space Club Coin", "SCC") ERC20Permit("Space Club Coin") {}


    using SafeMath for uint256;

    function airdrop(uint256 amount, address [] calldata recipients) external {
        require(amount > 0, "Airdrop: zero amount");
        require(recipients.length > 0, "Airdrop: recipients required");
        address sender = _msgSender();
        require(balanceOf(sender) >= amount.mul(recipients.length), "Airdrop: not enough balance");
        for (uint i = 0; i < recipients.length; i++) {
            _transfer(sender, recipients[i], amount);
        }
    }

    uint256[50] private ______gap;

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

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
