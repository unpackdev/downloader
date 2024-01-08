//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";


/// @title AUG token contract
/// @notice The AUG token contract is going to be owned by the AUG DAO
contract AUGToken is ERC20, Ownable {

    constructor()
        public
        ERC20("Augmatic", "AUG")
        {
            // Initial supply is 500 million (500e6)
            // We are using ether because the token has 18 decimals like ETH
            _mint(msg.sender, 500e6 ether);
        }
    
    /// @notice The OpenZeppelin renounceOwnership() implementation is
    /// overriden to prevent ownership from being renounced accidentally.
    function renounceOwnership()
        public
        override
        onlyOwner
    {
        revert("Ownership cannot be renounced");
    }
}
