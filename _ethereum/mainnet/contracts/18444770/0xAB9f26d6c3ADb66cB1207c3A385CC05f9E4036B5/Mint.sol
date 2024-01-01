// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

  Mint Protocol:    Levered Ethereum 2.0 staking yields.
  Telegram:         https://t.me/MintProtocol
  Website:          https://www.mintprotocol.app/
  Twitter:          https://twitter.com/MintProtocolApp
  Medium:           https://medium.com/@mintprotocol
  Dapp:             https://tech.mintprotocol.app/

  __    __   __    __   __   _______     __ __    __ __     _____    _______    _____     _____   _____    __      
 /_/\  /\_\ /\_\  /_/\ /\_\/\_______)\  /_/\__/\ /_/\__/\  ) ___ ( /\_______)\ ) ___ (   /\ __/\ ) ___ (  /\_\     
 ) ) \/ ( ( \/_/  ) ) \ ( (\(___  __\/  ) ) ) ) )) ) ) ) )/ /\_/\ \\(___  __\// /\_/\ \  ) )__\// /\_/\ \( ( (     
/_/ \  / \_\ /\_\/_/   \ \_\ / / /     /_/ /_/ //_/ /_/_// /_/ (_\ \ / / /   / /_/ (_\ \/ / /  / /_/ (_\ \\ \_\    
\ \ \\// / // / /\ \ \   / /( ( (      \ \ \_\/ \ \ \ \ \\ \ )_/ / /( ( (    \ \ )_/ / /\ \ \_ \ \ )_/ / // / /__  
 )_) )( (_(( (_(  )_) \ (_(  \ \ \      )_) )    )_) ) \ \\ \/_\/ /  \ \ \    \ \/_\/ /  ) )__/\\ \/_\/ /( (_____( 
 \_\/  \/_/ \/_/  \_\/ \/_/  /_/_/      \_\/     \_\/ \_\/ )_____(   /_/_/     )_____(   \/___\/ )_____(  \/_____/ 
                                                                                                                   
*/

contract Mint {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Mint Protocol";
    string public symbol = "MINT";
    uint8 public decimals = 18;

    constructor() {
      uint amount = 1_000_000 * 10 ** decimals;
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}
