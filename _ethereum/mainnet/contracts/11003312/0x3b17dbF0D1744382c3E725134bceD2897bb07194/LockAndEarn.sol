pragma solidity ^0.5.0;

/*
 * @title: SafeMath
 * @dev: Helper contract functions to arithmatic operations safely.
 */
contract SafeMath {
    function Sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function Add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function Mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}

/*
 * @title: Token
 * @dev: Interface contract for ERC20 tokens
 */
contract Token {
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}


contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract USDT is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @title: Lock and Earn
 */
contract LockAndEarn is SafeMath {
    // _kaiAddress: KAI ERC20 contract address
    // msg.sender: owner && operator
    constructor(uint256 _lockStartTime, uint256 _lockDays) public {
        owner = msg.sender;
        lockDays = _lockDays;
        lockStartTime = _lockStartTime;
        isEnded = false;
    }

    address public owner;
    uint256 public hardCap = 2000000000000000000000000; // 2000000 KAI
    uint256 public totalBonusUSDT;
    uint256 public minDeposit = 1000000000000000000000; // 1000 KAI
    uint256 public maxDeposit = 250000000000000000000000; // 250000 KAI
    address public kaiAddress = 0xD9Ec3ff1f8be459Bb9369b4E79e9Ebcf7141C093;
    address constant public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 public lockDays;
    uint256 public lockStartTime;
    uint8 public winPool;
    bool public isEnded;

    mapping(address => mapping(uint256 => uint256)) public balance;
    mapping(uint256 => uint256) public currentCapPool;
    mapping(address => bool) public isWithdrawBonus;
    mapping(address => mapping(uint256 => bool)) isWithdrawKAI;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Deposit ERC20's for saving
    function depositKAI(uint256 amount, uint256 poolIndex) public {
        require(isEnded != true);
        require(lockStartTime < now, 'Event has not been started yet');
        require(balance[msg.sender][poolIndex] == 0, "Can only deposit once");
        require (amount >= minDeposit, 'Amount must be equal or greater than 1000 KAI');
        require (amount <= maxDeposit, 'Amount must be equal or less than 250000 KAI');
        require(Add(currentCapPool[poolIndex], amount) <= hardCap, 'Exceed limit total cap');

        require(Token(kaiAddress).transferFrom(msg.sender, address(this), amount));

        balance[msg.sender][poolIndex] = amount;
        uint256 currentCap = currentCapPool[poolIndex];
        currentCapPool[poolIndex] = Add(currentCap, amount);
    }

    // Withdraw ERC20's to personal address
    function withdrawKAI(uint256 poolIndex) public {
        require(lockStartTime + lockDays * 1 days < now, "In locking period");
        require(isWithdrawKAI[msg.sender][poolIndex] != true, "Can only withdraw once");
        uint256 amount = balance[msg.sender][poolIndex];
        require(Token(kaiAddress).transfer(msg.sender, amount));
        isWithdrawKAI[msg.sender][poolIndex] = true;
    }
    
    function withdrawBonus() public {
        require(lockStartTime + lockDays * 1 days < now, "In locking period");
        require(balance[msg.sender][winPool] > 0, "Address has not deposited");
        require(isWithdrawBonus[msg.sender] != true, "Can only withdraw once");
        
        _withdrawBonus(msg.sender, winPool);
    }
    
    function _withdrawBonus(address addr, uint256 poolIndex) private {
        uint256 amount = balance[addr][poolIndex];
        uint256 currentCap = currentCapPool[winPool];

        uint256 bonus = Mul(amount, totalBonusUSDT) / currentCap;
        USDT(usdtAddress).transfer(msg.sender, bonus);
        isWithdrawBonus[msg.sender] = true;
    }
   
    function setWinningPoolAndBonus(uint256 _totalBonusUSDT, uint8 poolIndex) public onlyOwner {
        require(USDT(usdtAddress).balanceOf(address(this)) >= _totalBonusUSDT);

        totalBonusUSDT = _totalBonusUSDT;
        winPool = poolIndex;
    }
   
    // owner sets global variables the campaign ends
    function setEndedDeposit() public onlyOwner {
        isEnded = true;
    }
    
    // Below two emergency functions will be never used in normal situations.
    // These function is only prepared for emergency case such as smart contract hacking Vulnerability or smart contract abolishment
    // Withdrawn fund by these function cannot belong to any operators or owners.
    // Withdrawn fund should be distributed to individual accounts having original ownership of withdrawn fund.

    function emergencyWithdrawalETH(uint256 amount) public onlyOwner {
        require(msg.sender.send(amount));
    }
    
    function emergencyWithdrawalKAI(uint256 amount) public onlyOwner {
        Token(kaiAddress).transfer(msg.sender, amount);
    }
    
    function emergencyWithdrawalUSDT(uint256 amount) public onlyOwner {
        USDT(usdtAddress).transfer(msg.sender, amount);
    }
    
    function getMyBalance(uint256 poolIndex) public view returns (uint256) {
        return balance[msg.sender][poolIndex];
    }

    function getTimeStamp() public view returns (uint256) {
        return now;
    }
    
    // @notice Will receive any eth sent to the contract
    function () external payable {}
}