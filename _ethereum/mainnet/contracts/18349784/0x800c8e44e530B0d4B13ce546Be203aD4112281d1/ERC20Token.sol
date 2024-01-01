// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

    contract ERC20Token {
    string public name = "Zirka";
    string public symbol = "ZK";
    uint8 public decimals = 8;
    uint256 public totalSupply = 52000000 * 10 ** uint256(decimals);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    uint256 public lastTokenBurnTime;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event TokenBurned(address indexed owner, uint256 amount);
    event TokensExchanged(address indexed owner, address indexed recipient, uint256 amount, string goodsDescription);
    event AutoSwap(address indexed owner, uint256 amount);
    event EtherWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        lastTokenBurnTime = block.timestamp;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function buyTokens(uint256 amount) public payable returns (bool success) {
        require(msg.value >= amount, "Insufficient ETH sent");
        require(totalSupply >= amount, "Not enough tokens left for sale");

        balanceOf[msg.sender] += amount;
        totalSupply -= amount;

        emit Transfer(address(this), msg.sender, amount);
        emit TokensPurchased(msg.sender, amount, msg.value);
        return true;
    }

    function setNewOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function burnTokens(uint256 amount) public onlyOwner {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        lastTokenBurnTime = block.timestamp;

        emit Transfer(msg.sender, address(0), amount);
        emit TokenBurned(msg.sender, amount);
    }

    function exchangeTokensForGoods(address recipient, uint256 amount, string memory goodsDescription) public onlyOwner {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Invalid recipient address");

        balanceOf[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount); // Burn tokens

        emit TokensExchanged(msg.sender, recipient, amount, goodsDescription);
    }

    function autoSwap() public {
        // Implement your AUTOSWAP logic here
        // This function allows token holders to perform automated swaps
        emit AutoSwap(msg.sender, balanceOf[msg.sender]);
    }

    function withdrawEther(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner).transfer(amount);
        emit EtherWithdrawn(owner, amount);
    }
}