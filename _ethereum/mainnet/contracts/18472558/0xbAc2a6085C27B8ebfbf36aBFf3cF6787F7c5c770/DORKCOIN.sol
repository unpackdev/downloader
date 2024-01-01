/*                                                                       
Twitter：@SrPetersETH
NFT：@GodHatesNFTees
Telegram：@DORKcoin 



 |~~\  /~~\ |~~\| /
|   ||    ||__/|( 
|__/  \__/ |  \| \



*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DORKCOIN {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public taxAddress;
    uint256 public taxRate;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "DORKCOIN";
        symbol = "DORK";
        decimals = 18;
        totalSupply = 100000000000 * 10**uint256(decimals);
        taxAddress = 0x60156B26540050f4619DF5E5Ef80C5436bd08203;
        taxRate = 2;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        uint256 taxAmount = (value * taxRate) / 100;
        uint256 taxedValue = value - taxAmount;

        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[taxAddress] += taxAmount;
        balanceOf[to] += taxedValue;

        emit Transfer(msg.sender, to, taxedValue);
        emit Transfer(msg.sender, taxAddress, taxAmount);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 taxAmount = (value * taxRate) / 100;
        uint256 taxedValue = value - taxAmount;

        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[taxAddress] += taxAmount;
        balanceOf[to] += taxedValue;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, taxedValue);
        emit Transfer(from, taxAddress, taxAmount);
        return true;
    }
}