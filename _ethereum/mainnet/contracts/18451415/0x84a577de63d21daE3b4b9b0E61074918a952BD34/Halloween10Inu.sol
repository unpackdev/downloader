// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Halloween10Inu {
    using SafeMath for uint256;

    string public name = "Halloween10Inu";
    string public symbol = "HINU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 420e6 * 10**18;  // 420 Million tokens with 18 decimals
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner = msg.sender;
    address public placeholderWallet = 0x597fCffC688C2ffCc39cff0F266DB548906cEF07;  

    address public devWallet;
    uint256 public buyTax = 10;
    uint256 public sellTax = 30;
    mapping(address => bool) private _isBlacklisted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _devWallet) {
    devWallet = _devWallet;
    
    uint256 devAmount = 4.2e6 * 10**18;  // This is the 1% you mentioned
    uint256 placeholderAmount = totalSupply.mul(5).div(1000);  // 0.5% of the total supply
    
    balanceOf[msg.sender] = totalSupply.sub(devAmount).sub(placeholderAmount);
    balanceOf[devWallet] = devAmount;
    balanceOf[placeholderWallet] = placeholderAmount;

    emit Transfer(address(0), msg.sender, balanceOf[msg.sender]);
    emit Transfer(address(0), devWallet, devAmount);
    emit Transfer(address(0), placeholderWallet, placeholderAmount);
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