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
 * @title: Staking
 */
contract KaiStarter is SafeMath {
    // _kaiAddress: KAI ERC20 contract address
    // msg.sender: owner
    constructor(uint256 _contributeStartTime, uint256 _productReleasesTime, uint256 _lockDays) public {
        owner = msg.sender;
        isRevocable = false;
        isEnded = false;
        contributeStartTime = _contributeStartTime;
        productReleasesTime = _productReleasesTime;
        lockDays = _lockDays;
    }

    address public owner;
    address constant public kaiAddress = 0xD9Ec3ff1f8be459Bb9369b4E79e9Ebcf7141C093;
    address constant public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 public currentCap;
    uint256 public totalBackers;
    address[] public listBackers;
    uint256[] public contributedAmount;
    uint256 public contributeStartTime;
    uint256 public productReleasesTime;
    uint256 public lockDays;
    uint256 public maxContributionEachBacker = 500000000000000000000000; //500000 KAI
    uint256 public hardCap = 7500000000000000000000000; //7500000 KAI
    uint256 public minContributionEachBacker = 1000000000000000000000; //1000 KAI
    /* isRevocable is true if the campaign does not raise enough fund after the endTime passed, 
     * and contributors can withdraw their fund; 
     * otherwise it's false
     */
    bool public isRevocable;
    bool public isEnded; // isEnded is true when the campaign ends
    uint256 public totalBonusUSDT;
    mapping (address => bool) isWithdrawBonus;
    mapping (address => bool) isWithdrawContribution;

    
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // check if this backer has contributed to the compaign or not yet
    function existBacker(address backer) view private returns (uint256) {
        for (uint i; i< listBackers.length;i++){
          if (listBackers[i] == backer)
            return i+1;
        }
        return 0;
    }
    
    // owner sets global variables if the campaign fails
    function setRevocable() public onlyOwner {
        isRevocable = true;
        isEnded = true;
    }
    
    // owner sets global variables the campaign ends
    function setEnded() public onlyOwner {
        isEnded = true;
    }
    
    // backers contribute KAI to the campaign
    function contributeKAI(uint256 amount) public {
        require(now > contributeStartTime, 'Contribute time not comming');
        require(isEnded != true, 'Campaign ended');
        require(amount <= maxContributionEachBacker, 'Amount must be equal or smaller than 500000 KAI');
        require(amount >= minContributionEachBacker, 'Amount must be equal or greater than 1000 KAI');
        require(Add(amount, currentCap) <= hardCap, 'Exceed limit total cap');
        require(Token(kaiAddress).transferFrom(msg.sender, address(this), amount));
        
        uint256 indexBacker = existBacker(msg.sender);
        if (indexBacker != 0) {
            contributedAmount[indexBacker-1] += amount;
            require(contributedAmount[indexBacker-1] <= maxContributionEachBacker);
            
        } else {
            listBackers.push(msg.sender);
            contributedAmount.push(amount);
            totalBackers += 1;
        }
        
        currentCap = Add(currentCap, amount);
    }

    // Backers withdraw KAI to their personal addresses
    function withdrawKAI() public {
        if (isRevocable != true) {
            require((contributeStartTime + lockDays * 1 days) < now, "Locking period"); // ensure lock time is passeed
        }
        require(existBacker(msg.sender) != 0, "The backer not exist ");
        require(isWithdrawContribution[msg.sender] == false, "The backer withdraw only once"); //ensure the backer withdraw only once
        
        uint256 indexBacker = existBacker(msg.sender);
        uint256 amount = contributedAmount[indexBacker-1];
        require(Token(kaiAddress).transfer(msg.sender, amount));
        isWithdrawContribution[msg.sender] = true;
    }
    
    // Backers withdraw their distributed revenue
    function withdrawBonusUSDT() public {
        require((productReleasesTime + lockDays * 1 days) < now, "Locking period"); // ensure lock time is passeed
        require(existBacker(msg.sender) != 0, "The backer does not exist ");
        require(isWithdrawBonus[msg.sender] == false, "The backer withdraw only once"); // ensure the backer withdraw only once
        
        uint256 bonus = calculateBonus(msg.sender);
        USDT(usdtAddress).transfer(msg.sender, bonus);
        isWithdrawBonus[msg.sender] = true;
        
    }
    
    function calculateBonus(address backerAddr) private returns (uint256) {
        uint256 indexBacker = existBacker(backerAddr);
        uint256 amount = contributedAmount[indexBacker-1];
        uint256 bonus = Mul(amount, totalBonusUSDT) / currentCap;
        return bonus;
    }
   
     // owner contribute KAI to the campaign
    function fillRemaningKAI() public onlyOwner {
        uint256 amount = Sub(hardCap, currentCap);
        require(Add(amount, currentCap) == hardCap, 'Exceed limit total cap');
        require(Token(kaiAddress).transferFrom(msg.sender, address(this), amount));
        
        currentCap = Add(currentCap, amount);
    }
    
    function setContributeStartTime(uint256 _contributeStartTime) public onlyOwner {
        contributeStartTime = _contributeStartTime;
    }
   
    function setProductReleasesTime(uint256 _productReleasesTime) public onlyOwner {
        productReleasesTime = _productReleasesTime;
    }
    
    function setLockDays(uint256 _lockDays) public onlyOwner {
        lockDays = _lockDays;
    }
    
    function setMaxContributionEachBacker(uint256 _maxContributionEachBacker) public onlyOwner {
        maxContributionEachBacker = _maxContributionEachBacker;
    }
    
    function setTotalBonusUSDT(uint256 _totalBonusUSDT) public onlyOwner {
        require(USDT(usdtAddress).balanceOf(address(this)) >= _totalBonusUSDT);

        totalBonusUSDT = _totalBonusUSDT;
   }
    
    function getMyContribution(address backer) public view returns (uint256) {
        require(existBacker(backer) != 0);
        
        uint256 indexBacker = existBacker(backer);
        uint256 amount = contributedAmount[indexBacker-1];
        return amount;
    }

    function getTimeStamp() public view returns (uint256) {
        return now;
    }
    
    function emergencyWithdrawalETH(uint256 amount) public onlyOwner {
        require(msg.sender.send(amount));
    }
    
    function emergencyWithdrawalKAI(uint256 amount) public onlyOwner {
        require (now > (contributeStartTime + 32 * 1 weeks)); // after 32 weeks, owner can withdraw KAI
        Token(kaiAddress).transfer(msg.sender, amount);
    }
    
    function emergencyWithdrawalUSDT(uint256 amount) public onlyOwner {
        USDT(usdtAddress).transfer(msg.sender, amount);
    }
    
    // @notice Will receive any eth sent to the contract
    function () external payable {}
}