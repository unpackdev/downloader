// SPDX-License-Identifier: MIT
// HS to HNS Bridge Project

pragma solidity ^0.8.0;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
}

contract HandShake {
    using SafeMath for uint256;

    string public name = "HS";
    string public symbol = "HS";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
    uint256 public contractBalance;
    uint256 public maxClaimableTokens = 1500000000;
    uint256 public tokensClaimed;
    uint256 public claimFee = 500000000000000; // 0.0005 Ether in wei

    mapping(address => uint256) public balanceOf;

    constructor() {
        owner = msg.sender;
        totalSupply = 2000000000 * 10**uint256(decimals);
        balanceOf[msg.sender] = 500000000 * 10**uint256(decimals);
        balanceOf[address(this)] = 1500000000 * 10**uint256(decimals);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
    }

    function withdrawTokens(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount <= balanceOf[address(this)], "Insufficient contract balance");
        balanceOf[address(this)] = balanceOf[address(this)].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
    }

    function withdrawEther(address payable to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient contract balance");
        to.transfer(amount);
    }

    function updateName(string memory newName) public onlyOwner {
        name = newName;
    }

    function updateTicker(string memory newSymbol) public onlyOwner {
        symbol = newSymbol;
    }

    function claim() public payable {
        require(tokensClaimed < maxClaimableTokens, "All tokens have been claimed");
        require(balanceOf[address(this)] >= 2000 * 10**uint256(decimals), "Insufficient contract balance");
        require(msg.value >= claimFee, "Insufficient fee");
        tokensClaimed = tokensClaimed.add(2000 * 10**uint256(decimals));
        balanceOf[address(this)] = balanceOf[address(this)].sub(2000 * 10**uint256(decimals));
        balanceOf[msg.sender] = balanceOf[msg.sender].add(2000 * 10**uint256(decimals));
        contractBalance = contractBalance.add(msg.value).sub(claimFee);
    }
}