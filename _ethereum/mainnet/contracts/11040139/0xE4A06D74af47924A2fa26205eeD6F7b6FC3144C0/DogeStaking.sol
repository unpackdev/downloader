pragma solidity 0.5.16;

contract ERC20 {

    function transferFrom (address,address, uint256) external returns (bool);
    function balanceOf(address) public view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function transfer (address, uint256) external returns (bool);
    function burn (uint256) external returns (bool);
    function giveRewardsToStakers(address,uint256) external returns(bool); 

}

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
      _;
    }

    function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
      paused = false;
      emit Unpause();
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}


contract DogeStaking is Pausable{

    using SafeMath for uint256;

    address public uniV2DogeEth;
    address public uniV2EthUsdt;
    address public uniV2EthUsdc;
    
    address public puppyTokenAddress;
    
    uint256 public stakingRatioPairOne;
    uint256 public stakingRatioPairTwo;
    uint256 public stakingRatioPairThree;

    constructor(address ethDogeAddress, address ethUsdt, address ethUsdc, address _puppy) public Owned(msg.sender) {

    uniV2DogeEth = ethDogeAddress;
    uniV2EthUsdt = ethUsdt;
    uniV2EthUsdc = ethUsdc;
    
    puppyTokenAddress = _puppy;
    stakingRatioPairOne = 125;
    stakingRatioPairTwo = 30;
    stakingRatioPairThree = 30;
    

    }

    function setAddress(address dogeEthAddress, address ethUsdt, address ethUsdc) external onlyOwner returns(bool)  
    {
       
    uniV2DogeEth = dogeEthAddress;
    uniV2EthUsdt = ethUsdt;
    uniV2EthUsdc = ethUsdc;

            return true;
    }


    function setStakingRatio(uint256 value1, uint256 value2, uint256 value3) external onlyOwner returns(bool)  
    {
       
        stakingRatioPairOne = value1;
        stakingRatioPairTwo = value2;
        stakingRatioPairThree = value3;
        return true;
    }




    mapping (address => uint256) public dogeEthStaked;
    mapping (address => uint256) public dogeEthStakedTime;

    mapping (address => uint256) public ethUsdtStaked;
    mapping (address => uint256) public ethUsdtStakedTime;

    mapping (address => uint256) public ethUsdcStaked;
    mapping (address => uint256) public ethUsdcStakedTime;


   function stakedAllTokens (address userAddress) public view returns (uint256,uint256,uint256) {
       
       uint256 dogeEthStaked = dogeEthStaked[userAddress]; 
       uint256 ethUsdtStaked =  ethUsdtStaked[userAddress];  
       uint256 ethUsdcStaked = ethUsdcStaked[userAddress];    

       return (dogeEthStaked,ethUsdtStaked,ethUsdcStaked);

   }


   function StakingTime (address userAddress) public view returns (uint256,uint256,uint256) {
       
       uint256 dogeEthStakedTime = dogeEthStakedTime[userAddress]; 
       uint256 ethUsdtStakedTime = ethUsdtStakedTime[userAddress];  
       uint256 ethUsdcStakedTime = ethUsdcStakedTime[userAddress];    
       
       return (dogeEthStakedTime,ethUsdtStakedTime,ethUsdcStakedTime);
   }


    function stakeDogeEthTokens(uint256 amount) public returns (bool) {
       
       require(ERC20(uniV2DogeEth).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       require(dogeEthStaked[msg.sender] == 0, "Please claim  tokens first before new stake");
       uint256 checkAllowance = ERC20(uniV2DogeEth).allowance(msg.sender, address(this)); 
       dogeEthStaked[msg.sender] = amount;
       dogeEthStakedTime[msg.sender] = now;
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(uniV2DogeEth).transferFrom(msg.sender,address(this),amount),'transfer From failed');
        
    } 


    function claimableDogeETHPuppyTokens (address user) public view returns (bool,uint256) {
        
        if (dogeEthStaked[user] > 0){
            
            
            uint256 percent = dogeEthStaked[user].div(100);
            return (true,percent.mul(stakingRatioPairOne));
            
            
        } else {return (false,0);}
        
    }

    function claimEthDogePuppyTokens() public returns (bool) {
       
        require(dogeEthStaked[msg.sender]>0, "not staked any  tokens");
        require(now > dogeEthStakedTime[msg.sender].add(604800), "4 hours not completed yet"); 
        require(ERC20(uniV2DogeEth).transfer(msg.sender,dogeEthStaked[msg.sender]), " tokens Burned");

        uint256 percent = dogeEthStaked[msg.sender].div(100);
        require(ERC20(puppyTokenAddress).giveRewardsToStakers(msg.sender, percent.mul(stakingRatioPairOne)));
        dogeEthStaked[msg.sender] = 0;
        dogeEthStakedTime[msg.sender] = 0;    
        
    } 


    function stakeEthUsdtTokens(uint256 amount) public returns (bool) {
       
       require(ERC20(uniV2EthUsdt).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       require(ethUsdtStaked[msg.sender] == 0, "Please claim  tokens first before new stake");
       uint256 checkAllowance = ERC20(uniV2EthUsdt).allowance(msg.sender, address(this)); 
       ethUsdtStaked[msg.sender] = amount;
       ethUsdtStakedTime[msg.sender] = now;
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(uniV2EthUsdt).transferFrom(msg.sender,address(this),amount),'transfer From failed');
        
    } 

    function claimableEthUsdtPuppyTokens (address user) public view returns (bool,uint256) {
        
        if (ethUsdtStaked[user] > 0){
            
            uint256 percent = ethUsdtStaked[user].div(100);
            return (true,percent.mul(stakingRatioPairTwo));
            
            
        } else {return (false,0);}
        
    }


    function claimEthUsdtPuppyTokens() public returns (bool) {
       
        require(ethUsdtStaked[msg.sender]>0, "not staked any  tokens");
        require(now > ethUsdtStakedTime[msg.sender].add(604800), "4 hours not completed yet"); 
        
        uint256 percent = ethUsdtStaked[msg.sender].div(100);

        require(ERC20(uniV2EthUsdt).transfer(msg.sender,ethUsdtStaked[msg.sender]), " tokens Burned");
        require(ERC20(puppyTokenAddress).giveRewardsToStakers(msg.sender,percent.mul(stakingRatioPairTwo)), "mint failed");

        ethUsdtStaked[msg.sender] = 0;
        ethUsdtStakedTime[msg.sender] = 0;
        
    } 

    function stakeEthUsdcTokens(uint256 amount) public returns (bool) {
       
       require(ERC20(uniV2EthUsdc).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       require(ethUsdcStaked[msg.sender] == 0, "Please claim  tokens first before new stake");
       uint256 checkAllowance = ERC20(uniV2EthUsdc).allowance(msg.sender, address(this)); 
       ethUsdcStaked[msg.sender] = amount;
       ethUsdcStakedTime[msg.sender] = now;
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(uniV2EthUsdc).transferFrom(msg.sender,address(this),amount),'transfer From failed');
        
    } 

    function claimableEthUsdcTokens (address user) public view returns (bool,uint256) {
        
        if (ethUsdcStaked[user] > 0){
            
            uint256 percent = ethUsdcStaked[user].div(100);
            return (true,percent.mul(stakingRatioPairThree));
            
            
        } else {return (false,0);}
        
    }

    function claimEthUsdcTokens() public returns (bool) {
       
        require(ethUsdcStaked[msg.sender]>0, "not staked any  tokens");
        require(now > ethUsdcStakedTime[msg.sender].add(604800), "4 hours not completed yet"); 
        uint256 percent = ethUsdcStaked[msg.sender].div(100);
        require(ERC20(uniV2EthUsdc).transfer(msg.sender,ethUsdcStaked[msg.sender]), " tokens Burned");
        require(ERC20(puppyTokenAddress).giveRewardsToStakers(msg.sender,percent.mul(stakingRatioPairThree)));

        ethUsdcStaked[msg.sender] = 0;
        ethUsdcStakedTime[msg.sender] = 0;
        
    } 


   function transferAnyERC20Token(address tokenAddress, uint tokens) public whenNotPaused onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        return ERC20(tokenAddress).transfer(owner, tokens);
    }}