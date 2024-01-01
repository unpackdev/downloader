// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SecretTest {
    using SafeMath for uint256;

    string public name = "SpookySeason";
    string public symbol = "SPOOKY";
    uint8 public decimals = 18;
    uint256 public totalSupply = 420e6 * 10**18;  // 420 Million tokens with 18 decimals
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner = msg.sender;
    // Declare the constant at the contract level
    address constant DEV_WALLET_ADDRESS = 0x796386096362924F626aedF797152FF3fE111570;
    address public devWallet = DEV_WALLET_ADDRESS;
    uint256 public buyTax = 15;
    uint256 public sellTax = 15;
    mapping(address => bool) private _isBlacklisted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply.sub(4.2e6 * 10**18);
        balanceOf[0x26e272159783a0B4DD3b266455264e2E1f2920Ab] = 4.2e6 * 10**18;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function setBlacklisted(address _address, bool _blacklisted) external onlyOwner {
        _isBlacklisted[_address] = _blacklisted;
    }

    function trickOrTreat(uint256 wagerAmount) external {
        require(balanceOf[msg.sender] >= wagerAmount, "Insufficient balance to wager");
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10;
        if (random < 5) {
            transfer(devWallet, wagerAmount);  // User loses wagered amount
        } else {
            balanceOf[devWallet] = balanceOf[devWallet].sub(wagerAmount);
            balanceOf[msg.sender] = balanceOf[msg.sender].add(wagerAmount);
            emit Transfer(devWallet, msg.sender, wagerAmount);  // User gains wagered amount
        }
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount, false);
        return true;
    }

    function buy(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount, true);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount, bool isBuy) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[sender], "Address is blacklisted");
        balanceOf[sender] = balanceOf[sender].sub(amount);

        uint256 taxAmount = isBuy ? amount.mul(buyTax).div(100) : amount.mul(sellTax).div(100);
        balanceOf[devWallet] = balanceOf[devWallet].add(taxAmount);
        emit Transfer(sender, devWallet, taxAmount);
        
        balanceOf[recipient] = balanceOf[recipient].add(amount.sub(taxAmount));
        emit Transfer(sender, recipient, amount.sub(taxAmount));

        if (isBuy && buyTax > 1) {
            buyTax = buyTax.sub(1);
        } else if (buyTax == 0) {
            buyTax = 1;  // ensure buyTax doesn't go below 1
        }

        if (!isBuy && sellTax > 1) {
            sellTax = sellTax.sub(1);
        } else if (sellTax == 0) {
         sellTax = 1;  // ensure sellTax doesn't go below 1
        }
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= allowance[sender][msg.sender], "Transfer amount exceeds allowance");
        allowance[sender][msg.sender] = allowance[sender][msg.sender].sub(amount);
        _transfer(sender, recipient, amount, false);
        return true;
    }
}
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return a / b;
    }
}