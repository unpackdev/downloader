// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./Owner.sol";
import "./ERC20.sol";
import "./Auction.sol";
import "./Math.sol";

/// @dev Dilithium ERC20 contract
contract Dilithium is ERC20("Dilithium", "DIL"), Owner {
    /// @dev mint allocates new DIL supply to an account.
    /// @param account is the beneficiary.
    /// @param amount is the number of DIL to issue.
    function mint(address account, uint256 amount) public isOwner() {
        _mint(account, amount);
    }

    /// @dev burn destroys the given amount of the sender's balance .
    /// @param amount is the number of DIL to destroy.
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
