//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";


/* This contract created to support token distribution in JaxNet project
*  By default, all transfers are paused. Except function, transferFromOwner, which allows
*  to distribute tokens.
*  Supply is limited to  40000000
*  Owner of contract may burn coins from his account
*/

contract Wrapped_JAXNET_Token_ERC20 is Ownable, ERC20, Pausable {

    constructor(address owner) ERC20("Wrapped JAXNET", "WJXN") {
        _mint(owner, 40002164);
        _pause();
        transferOwnership(owner);
    }

    function decimals() public pure override  returns (uint8) {
        return 0;
    }




    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be contract owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
      * @dev Check if system is not paused.
    */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }
}