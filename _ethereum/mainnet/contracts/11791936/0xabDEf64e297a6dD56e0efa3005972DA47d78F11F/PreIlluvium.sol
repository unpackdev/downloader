//SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";


contract PreIlluvium is ERC20("Pre Illuvium Token", "preILV"), Ownable, Pausable {

    using SafeMath for uint;
    
    constructor(uint supply) {
        _mint(msg.sender, supply);
    }

     /**
     * @dev Mints `amount` tokens to `to`
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - only the owner can call this function
     */
    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
    }

     /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint amount) external {
        require(allowance(account, _msgSender()) >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), allowance(account, _msgSender()).sub(amount));
        _burn(account, amount);
    }

    /**
     * @dev Overrides and calls super {ERC20-transfer}
     *
     * See {ERC20-transfer}
     *
     * Requirements:
     *
     * - `recipient` cannot be `address(this)`
     */
    function transfer(address recipient, uint amount) 
        public 
        override 
        returns (bool)        
    {
        require(recipient != address(this), "PreIlluvium: Invalid recipient");
        super.transfer(recipient, amount);
    }

     function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal 
        virtual 
        override 
    {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function pause(bool shouldPause) external onlyOwner {
        if (shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function destroy() external onlyOwner {
        selfdestruct(msg.sender);
    }
}
