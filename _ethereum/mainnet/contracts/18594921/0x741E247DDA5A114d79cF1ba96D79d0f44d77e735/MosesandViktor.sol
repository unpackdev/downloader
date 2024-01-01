// SPDX-License-Identifier: MIT
/*

$$\      $$\  $$$$$$\   $$$$$$\  $$$$$$$$\  $$$$$$\        
$$$\    $$$ |$$  __$$\ $$  __$$\ $$  _____|$$  __$$\       
$$$$\  $$$$ |$$ /  $$ |$$ /  \__|$$ |      $$ /  \__|      
$$\$$\$$ $$ |$$ |  $$ |\$$$$$$\  $$$$$\    \$$$$$$\        
$$ \$$$  $$ |$$ |  $$ | \____$$\ $$  __|    \____$$\       
$$ |\$  /$$ |$$ |  $$ |$$\   $$ |$$ |      $$\   $$ |      
$$ | \_/ $$ | $$$$$$  |\$$$$$$  |$$$$$$$$\ \$$$$$$  |      
\__|     \__| \______/  \______/ \________| \______/       
 $$$$$$\  $$\   $$\ $$$$$$$\                               
$$  __$$\ $$$\  $$ |$$  __$$\                              
$$ /  $$ |$$$$\ $$ |$$ |  $$ |                             
$$$$$$$$ |$$ $$\$$ |$$ |  $$ |                             
$$  __$$ |$$ \$$$$ |$$ |  $$ |                             
$$ |  $$ |$$ |\$$$ |$$ |  $$ |                             
$$ |  $$ |$$ | \$$ |$$$$$$$  |                             
\__|  \__|\__|  \__|\_______/                              
$$\    $$\ $$$$$$\ $$\   $$\ $$$$$$$$\  $$$$$$\  $$$$$$$\  
$$ |   $$ |\_$$  _|$$ | $$  |\__$$  __|$$  __$$\ $$  __$$\ 
$$ |   $$ |  $$ |  $$ |$$  /    $$ |   $$ /  $$ |$$ |  $$ |
\$$\  $$  |  $$ |  $$$$$  /     $$ |   $$ |  $$ |$$$$$$$  |
 \$$\$$  /   $$ |  $$  $$<      $$ |   $$ |  $$ |$$  __$$< 
  \$$$  /    $$ |  $$ |\$$\     $$ |   $$ |  $$ |$$ |  $$ |
   \$  /   $$$$$$\ $$ | \$$\    $$ |    $$$$$$  |$$ |  $$ |
    \_/    \______|\__|  \__|   \__|    \______/ \__|  \__|
                                                           
                                                      

                                    
**/

pragma solidity ^0.8.0;

contract MosesandViktor {
    string public name = "MOSES AND VIKTOR";
    string public symbol = "MAV";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1e12 * 1e18; // 1 trillion tokens with 18 decimals
    uint256 public maxSellPercentage = 1; // 0.001% represented as 1 (0.001 * 1000)

    address public owner;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event MaxSellPercentageChanged(uint256 newPercentage);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function setMaxSellPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage >= 0, "Percentage cannot be negative");
        maxSellPercentage = _newPercentage;
        emit MaxSellPercentageChanged(_newPercentage);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        if (msg.sender != owner) {
            uint256 maxSellAmount = totalSupply * maxSellPercentage / 1e3; // Convert maxSellPercentage to 0.001%
            require(value <= maxSellAmount, "Sell amount exceeds maximum allowed percentage");
        }

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}