/*
 ______   __  __   ___ __ __   ___ __ __    ________  _________   ______   ________   ______   ________  _________  ________   __          
/_____/\ /_/\/_/\ /__//_//_/\ /__//_//_/\  /_______/\/________/\ /_____/\ /_______/\ /_____/\ /_______/\/________/\/_______/\ /_/\         
\::::_\/_\:\ \:\ \\::\| \| \ \\::\| \| \ \ \__.::._\/\__.::.__\/ \:::__\/ \::: _  \ \\:::_ \ \\__.::._\/\__.::.__\/\::: _  \ \\:\ \        
 \:\/___/\\:\ \:\ \\:.      \ \\:.      \ \   \::\ \    \::\ \    \:\ \  __\::(_)  \ \\:(_) \ \  \::\ \    \::\ \   \::(_)  \ \\:\ \       
  \_::._\:\\:\ \:\ \\:.\-/\  \ \\:.\-/\  \ \  _\::\ \__  \::\ \    \:\ \/_/\\:: __  \ \\: ___\/  _\::\ \__  \::\ \   \:: __  \ \\:\ \____  
    /____\:\\:\_\:\ \\. \  \  \ \\. \  \  \ \/__\::\__/\  \::\ \    \:\_\ \ \\:.\ \  \ \\ \ \   /__\::\__/\  \::\ \   \:.\ \  \ \\:\/___/\ 
    \_____\/ \_____\/ \__\/ \__\/ \__\/ \__\/\________\/   \__\/     \_____\/ \__\/\__\/ \_\/   \________\/   \__\/    \__\/\__\/ \_____\/ 


    Website:     https://summitcapital.xyz
    Docs:        https://docs.summitcapital.xyz
    Twitter/X:   https://Twitter.com/SummitAlgo
    Telegram:    https://t.me/summitcapital
    Medium:      https://summitcapital.medium.com/

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SummitCoin {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Summit";
    string public symbol = "SUMT";
    uint8 public decimals = 18;

    constructor() {
      balanceOf[msg.sender] += 10_000_000 * 10 ** decimals;
      totalSupply += 10_000_000 * 10 ** decimals;
      emit Transfer(address(0), msg.sender, 10_000_000 * 10 ** decimals);
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
