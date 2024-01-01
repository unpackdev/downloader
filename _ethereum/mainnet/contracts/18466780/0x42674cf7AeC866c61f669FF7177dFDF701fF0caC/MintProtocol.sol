// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*

   _____  .__        __    __________                __                      .__   
  /     \ |__| _____/  |_  \______   \_______  _____/  |_  ____   ____  ____ |  |  
 /  \ /  \|  |/    \   __\  |     ___/\_  __ \/  _ \   __\/  _ \_/ ___\/  _ \|  |  
/    Y    \  |   |  \  |    |    |     |  | \(  <_> )  | (  <_> )  \__(  <_> )  |__
\____|__  /__|___|  /__|    |____|     |__|   \____/|__|  \____/ \___  >____/|____/
        \/        \/                                                 \/            

  Mint Protocol:    Levered Ethereum 2.0 staking yields.
  Telegram:         https://t.me/MintProtocol
  Website:          https://www.mintprotocol.app/
  Twitter:          https://twitter.com/MintProtocolApp
  Medium:           https://medium.com/@mintprotocol
  Dapp:             https://tech.mintprotocol.app/


*/

contract MintProtocol {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Mint Protocol";
    string public symbol = "MINT";
    uint8 public decimals = 18;

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
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
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
    }
}
