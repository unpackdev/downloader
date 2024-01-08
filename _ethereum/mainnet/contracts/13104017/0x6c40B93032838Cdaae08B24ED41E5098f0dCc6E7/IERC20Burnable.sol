// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Burnable {
    
    /**
     * @dev Burns `amount` tokens from the caller account
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @dev Burns `amount` tokens from caller using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     */
    function burnFrom(address account, uint256 amount) external returns (bool);

}