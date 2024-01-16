//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Roles.sol";


/**
    @title Hawex ERC20 Token
 */
contract HawexToken is ERC20, Ownable, ExchangerRole, Pausable{
    using SafeMath for uint;

    /**
        @param initialIssue issue that will be minted initally
     */
    constructor(uint initialIssue) ERC20("HAWEX", "HWX") {
        mint(initialIssue);
    }

    /**
        @dev overrider of ERC20 _transfer function
        when paused owner and exchangers only can use transfer 
     */    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (!paused())
            super._transfer(sender, recipient, amount);
        else {
            if (isOwner() || isExchanger(msg.sender))
            super._transfer(sender, recipient, amount);
            else 
                revert("transferring is paused");
        }
    }

    /**
        @notice add Pauser role to `account`
        @dev only for Owner
        @param account role recipient
     */
    function addPauser(address account) public onlyOwner {
        require(!isPauser(account), "[Pauser Role]: account already has Pauser role");
        _addPauser(account);
    }

    /**
        @notice remove Pauser role from `account`
        @dev only for Owner
        @param account address for role revocation
     */
    function removePauser(address account) public onlyOwner {
        require(isPauser(account), "[Pauser Role]: account has not Pauser role");
        _removePauser(account);
    }

    /**
        @notice add Exchanger role to `account`
        @dev only for Owner
        @param account role recipient
     */
    function addExchanger(address account) public onlyOwner {
        require(!isExchanger(account), "[Exchanger Role]: account already has Exchanger role");
        _addExchanger(account);
    }

    /**
        @notice remove Exchanger role from `account`
        @dev only for Owner
        @param account address for role revocation
     */
    function removeExchanger(address account) public onlyOwner {
        require(isExchanger(account), "[Exchanger Role]: account has not Exchanger role");
        _removeExchanger(account);
    }

    /**
        @notice mint new tokens. Max supply = 10_000_000_000e18
        @dev only for Owner
        @param amount minting amount
     */
    function mint(uint amount) public onlyOwner {
        require(totalSupply() + amount <= 10000000000e18, "total issue must be leen than 10 billion");
        _mint(msg.sender, amount);
    } 

    /**
        @notice burn tokens
        @dev only for Owner
        @param amount burning amount
     */
    function burn(uint amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
}