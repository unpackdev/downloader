//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";


/// @title AGM token contract
/// @notice The AGM token contract is going to be owned by the AGM DAO
contract AGMToken is ERC20, Ownable {

    constructor()
        public
        ERC20("Augmatic", "AGM")
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
