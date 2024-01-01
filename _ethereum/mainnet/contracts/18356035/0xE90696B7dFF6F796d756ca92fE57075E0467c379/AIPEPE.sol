///SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "./ERC20.sol";

/// @title AIPEPE: An erc20 token 
contract AIPEPE is ERC20 {
    ///@notice max supply 
    uint256 constant private MAX_SUPPLY = 9_999_999_999 * 1e18; //9,999,999,999 Tokens
    ///@dev create AIPEPE token contract, uses openezeppelin ERC20.
    /// mint the max Supply to the owner wallet during deployment.
    constructor () ERC20 ("AIPEPE", "AIPEPE"){
        _mint(msg.sender, MAX_SUPPLY);
    }
}