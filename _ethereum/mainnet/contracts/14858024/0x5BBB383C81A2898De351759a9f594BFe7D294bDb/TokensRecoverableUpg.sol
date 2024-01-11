// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity >=0.6.2 <0.8.0;

import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

abstract contract TokensRecoverableUpg is OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function recoverTokens(IERC20Upgradeable token) public onlyOwner() 
    {
        require (canRecoverTokens(token));    
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverETH(uint256 amount) public onlyOwner() 
    {        
        msg.sender.transfer(amount);
    }

    function canRecoverTokens(IERC20Upgradeable token) internal virtual view returns (bool) 
    { 
        return address(token) != address(this); 
    }

}