// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Ownable.sol";


contract LogoToken is ERC20, AccessControl {
    bytes32 public constant COIN_MASTER_ROLE = keccak256("COIN_MASTER_ROLE");
    
    constructor(address initialRecipient) 
    ERC20("LogoToken", "LOGO") 
    {
      _setupRole(getRoleAdmin(COIN_MASTER_ROLE), msg.sender);
      grantRole(COIN_MASTER_ROLE, msg.sender);     
      issueLogo(initialRecipient, 75e22);
    }

    
    function issueLogo(address recipient, uint256 amount)
        public
    {
        require(hasRole(COIN_MASTER_ROLE, msg.sender), "Caller is not a coin master");
        _mint(recipient, amount);
    }

    function burnLogo(address recipient, uint256 amount)
        public
    {
        require(hasRole(COIN_MASTER_ROLE, msg.sender), "Caller is not a coin master");
        _burn(recipient, amount);
    }
    
}