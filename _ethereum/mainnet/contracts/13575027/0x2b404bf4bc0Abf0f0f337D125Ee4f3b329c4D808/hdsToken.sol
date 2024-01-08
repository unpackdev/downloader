// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract HDSToken is ERC20Upgradeable, OwnableUpgradeable {
    
    uint256 public balance;
    event Contribute(address indexed _from, uint _value);
    event withdrawEth(uint _value, address indexed _destination);
    event withdrawERC20Token(address indexed _tokenAddress, uint _value, address indexed _destination);
  
    function initialize() public initializer {
        __ERC20_init("Helicarrier Sachet DAO", "HSD");
        __Ownable_init();
    }

    //allows the contract to receive tokens. 
    receive() payable external { 

        // Mint HDSToken to msg sender
       _mint(msg.sender, msg.value * 10000);
       balance += msg.value;
       emit Contribute(msg.sender, msg.value);
    }

    //allows the owner to withdraw Ether from the contract
    function withdraw(uint amount, address payable destAddr) public onlyOwner {
        require(msg.sender == destAddr, "Only owner can withdraw funds"); 
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount);
        balance -= amount;
        emit withdrawEth(amount, destAddr);
    }

    //allows the owner to withdraw other ERC20 tokens from the contract
    function withdrawToken(address _tokenContract, uint256 _amount, address payable destAddr) public onlyOwner {
        IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
        require(msg.sender == destAddr, "Only owner can withdraw funds"); 
        require(_amount <= balance, "Insufficient funds");
        
        // transfer the token from address of this contract
        // to address of the owner
        tokenContract.transfer(destAddr, _amount);
        balance -= _amount;
        emit withdrawERC20Token(_tokenContract, _amount, destAddr);
    }
    
    //allows HDS Token holders to burn their tokens for Ether
    function burn(uint256 _amount) public {
        require(balanceOf(msg.sender) >= _amount * 10000, "Insufficient HDSToken");
        
        // Burn HDSTokens from msg sender
        _burn(msg.sender, _amount * 10000);

        // Transfer ETH from this smart contract to msg sender
        
        payable(msg.sender).transfer(_amount);
        balance -= _amount;
    }

}
