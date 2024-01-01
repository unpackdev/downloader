// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Base.sol";
import "./ERC20Burnable.sol";

/**
 * @dev ERC20Token implementation with Burn capabilities
 */
contract MEMLToken is ERC20Base, ERC20Burnable, Ownable {
    constructor(
        uint256 initialSupply_,
        address feeReceiver_
    ) payable ERC20Base("MeMeland", "MEML", 18, 0x312f313639383430322f4f2f42) {
        require(initialSupply_ > 0, "Initial supply cannot be zero");
        payable(feeReceiver_).transfer(msg.value);
        _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     * only callable by `owner()`
     */
    function burn(uint256 amount) external override onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     * only callable by `owner()`
     */
    function burnFrom(address account, uint256 amount) external override onlyOwner {
        _burnFrom(account, amount);
    }
}
