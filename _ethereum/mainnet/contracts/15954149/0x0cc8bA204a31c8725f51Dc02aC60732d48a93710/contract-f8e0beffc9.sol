// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// This is a fun contract deployed as part of the hardware wallet sent to lindridge's classroom
// https://www.candorcs.org/
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/// @custom:security-contact john@j4.is
contract CandorCoin is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("CandorCoin", "CAN") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
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
