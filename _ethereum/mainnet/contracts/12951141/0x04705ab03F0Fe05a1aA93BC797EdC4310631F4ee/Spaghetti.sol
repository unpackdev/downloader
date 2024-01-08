// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

// FSMToken with Governance.
contract Spaghetti is ERC20Capped, Ownable {

    uint256 constant FSM_TOKEN_CAP = 3_581_382_600;
    
    constructor () 
        public 
        ERC20Capped(FSM_TOKEN_CAP * 1e18) 
        ERC20("FSMCoin", "FSM")
    {
        
    }

    /// @notice Mint FSMTokens called by an authorized minter 
    function mint(address to, uint amount) 
        public 
        onlyOwner 
    {
        _mint(to, amount);
    }
}