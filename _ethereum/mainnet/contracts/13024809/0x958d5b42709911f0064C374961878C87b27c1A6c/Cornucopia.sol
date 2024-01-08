// SPDX-License-Identifier: MIT

/*  $URUS is the governance token of the ERC20 Ecosystem
    $WAGYU staking control token
    $CORNUCOPIA bridge nexus control token
    t.me/Cornucopia_Urus 3 of 7
    */
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract CORNUCOPIA is ERC20, Pausable, Ownable {
    constructor() ERC20("CORNUCOPIA - t.me/Cornucopia_Urus", "CORNUCOPIA") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}