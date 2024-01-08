// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./BEP20Capped.sol";
import "./BEP20Mintable.sol";
import "./BEP20Burnable.sol";
import "./BEP20Operable.sol";
import "./BEP20Pausable.sol";
import "./BEP20Snapshot.sol";
import "./BEP20Deflationary.sol";

import "./TokenRecover.sol";

contract FintehToken is BEP20Capped, BEP20Mintable, BEP20Burnable, BEP20Operable, BEP20Pausable, BEP20Deflationary, TokenRecover {
    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 cap_,
        uint256 initialBalance_,
        address payable feeReceiver_
    )
      BEP20(name_, symbol_)
      BEP20Capped(cap_)
      payable
    {
        _setupDecimals(decimals_);
        _mint(_msgSender(), initialBalance_);
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {BEP20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override(BEP20, BEP20Capped) onlyOwner {
        super._mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * NOTE: restricting access to owner only. See {BEP20Mintable-finishMinting}.
     */
    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }

    function transfer(address recipient, uint256 amount) public override(BEP20Pausable, BEP20) returns (bool) {
        super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(BEP20Pausable, BEP20) returns (bool) {
        super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override(BEP20Pausable, BEP20) returns (bool) {
        super.approve(spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public override(BEP20Pausable, BEP20) returns (bool) {
        super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override(BEP20Pausable, BEP20) returns (bool) {
        super.decreaseAllowance(spender, subtractedValue);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override(BEP20Deflationary, BEP20) {
        super._transfer(sender, recipient, amount);
    }
}
