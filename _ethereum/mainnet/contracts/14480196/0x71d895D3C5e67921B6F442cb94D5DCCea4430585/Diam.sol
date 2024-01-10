// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Diam is ERC20, Ownable {

    constructor() ERC20("Diam", "DIAM") {
        _mint(msg.sender, 10000000000000000000000000000);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`), with all the tokens held by the owner account.
     * If current owner has 0 balance, then transferOwnership can be called.
     */
    function transferOwnershipWithAmount(address newOwner, uint256 amount) external onlyOwner {
       transfer(newOwner, amount);
       transferOwnership(newOwner);
    }

}