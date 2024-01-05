// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./SafeMath.sol";

contract BribeToken is Context, AccessControl, ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _mint(to, amount);
    }
}