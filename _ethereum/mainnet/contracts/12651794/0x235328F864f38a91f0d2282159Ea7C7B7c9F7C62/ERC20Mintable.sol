// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @dev Extension of `ERC20` that allows owner to mint tokens.
 *
 * At construction, the deployer of the contract is the owner.
 */
abstract contract ERC20Mintable is ERC20, Ownable {
    /**
     * @dev See `ERC20._mint`.
     *
     * Requirements:
     *
     * - the caller must be the `Owner`.
     */
    function mint(address account, uint256 amount) public onlyOwner virtual returns (bool) {
        _mint(account, amount);
        return true;
    }
}
