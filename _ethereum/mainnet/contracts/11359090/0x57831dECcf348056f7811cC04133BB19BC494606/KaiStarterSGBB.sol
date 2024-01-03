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
    
    function Mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
 * @title: Staking
 */
contract KaiStarterSGBB is SafeMath {
    // _kaiAddress: KAI ERC20 contract address
    // msg.sender: owner
    constructor(uint256 _contributeStartTime, uint256 _lockDays) public {
        owner = msg.sender;
        isEnded = false;
        contributeStartTime = _contributeStartTime;
        lockDays = _lockDays;
    }

    address constant KAI_ADDRESS = 0xD9Ec3ff1f8be459Bb9369b4E79e9Ebcf7141C093;
    address constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 constant public HARD_CAP = 10000000000000000000000000; // 10000000 KAI
    uint256 constant public MAX_CONTRIBUTION_EACH_BACKER = 500000000000000000000000; // 500000 KAI
    uint256 constant public AMOUNT_MULTIPLES = 1000000000000000000000; // 1000 KAI

    address private owner;
    uint256 public currentCap;
    uint256 public totalBackers;
    uint256 public contributeStartTime;
    uint256 public lockDays;
    bool public isEnded; // isEnded is true when the campaign ends
    uint256 public totalBonusUSDT;
    
    mapping (address => uint256) public contributedAmount;
    mapping (address => bool) public isWithdrawBonus;
    mapping (address => bool) public isWithdrawContribution;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // backers contribute KAI to the campaign
    function contributeKAI(uint256 _amount) public {
        require(isEnded != true, 'Campaign ended');
        require(now > contributeStartTime, 'Contribute time not comming');
        require(Add(contributedAmount[msg.sender], _amount) <= MAX_CONTRIBUTION_EACH_BACKER, "Exceed limit personal cap");
        require(Mod(_amount, AMOUNT_MULTIPLES) == 0, "Amount must be in multiples of 1,000 KAI");
        require(Add(_amount, currentCap) <= HARD_CAP, 'Exceed limit total cap');
        require(Token(KAI_ADDRESS).transferFrom(msg.sender, address(this), _amount));
        
        if (contributedAmount[msg.sender] == 0) {
            totalBackers += 1;
        }
        
        contributedAmount[msg.sender] = Add(contributedAmount[msg.sender], _amount);
        currentCap = Add(currentCap, _amount);
    }

    // Backers withdraw KAI to their personal addresses
    function withdrawKAI() public {
        require((contributeStartTime + lockDays * 1 days) < now, "Locking period"); // ensure lock time is passeed
        require(isWithdrawContribution[msg.sender] == false, "The backer withdraw only once"); //ensure the backer withdraw only once
        
        uint256 amount = contributedAmount[msg.sender];
        require(Token(KAI_ADDRESS).transfer(msg.sender, amount));
        
        isWithdrawContribution[msg.sender] = true;
    }
    
    // Backers withdraw their distributed revenue
    function withdrawBonusUSDT() public {
        require((contributeStartTime + lockDays * 1 days) < now, "Locking period"); // ensure lock time is passeed
        require(isWithdrawBonus[msg.sender] == false, "The backer withdraw only once"); // ensure the backer withdraw only once
        
        uint256 amount = contributedAmount[msg.sender];
        uint256 bonus = Mul(amount, totalBonusUSDT) / currentCap;
        USDT(USDT_ADDRESS).transfer(msg.sender, bonus);
        isWithdrawBonus[msg.sender] = true;
    }
    
    function setTotalBonusUSDT(uint256 _totalBonusUSDT) public onlyOwner {
        require(USDT(USDT_ADDRESS).balanceOf(address(this)) >= _totalBonusUSDT);

        totalBonusUSDT = _totalBonusUSDT;
    }
    
    // owner sets global variables the campaign ends
    function setEnded() public onlyOwner {
        isEnded = true;
    }
    
    
    function getMyContribution(address _backer) public view returns (uint256) {
        return contributedAmount[_backer];
    }
    
    function getBalanceKAIContract() public view returns (uint256) {
        return Token(KAI_ADDRESS).balanceOf(address(this));
    }
    
    function getBalanceUSDTContract() public view returns (uint256) {
        return USDT(USDT_ADDRESS).balanceOf(address(this));
    }

    function getTimeStamp() public view returns (uint256) {
        return now;
    }
    
    function emergencyWithdrawalETH(uint256 amount) public onlyOwner {
        require(msg.sender.send(amount));
    }
    
    function emergencyWithdrawalKAI(uint256 amount) public onlyOwner {
        Token(KAI_ADDRESS).transfer(msg.sender, amount);
    }
    
    function emergencyWithdrawalUSDT(uint256 amount) public onlyOwner {
        USDT(USDT_ADDRESS).transfer(msg.sender, amount);
    }
    
    // @notice Will receive any eth sent to the contract
    function () external payable {}
}