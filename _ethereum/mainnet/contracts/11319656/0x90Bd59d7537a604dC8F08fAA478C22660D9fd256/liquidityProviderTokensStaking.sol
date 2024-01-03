pragma solidity 0.5.16;

contract ERC20 {

    function transferFrom (address,address, uint256) external returns (bool);
    function balanceOf(address) public view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function transfer (address, uint256) external returns (bool);
    function giveRewardsToStakers(address,uint256) external returns(bool);
    function burn(uint256 amount, bytes calldata data) external;

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


contract liquidityProviderTokensStaking is Pausable{

    using SafeMath for uint256;

    address public plaasTokenContract;
    address payable private wallet;

    uint256 public walletFees;
    address public farmTokenAddress;
    uint256 public minimumTokens;
    uint256 public maximumStake;
    uint256 public totalStaked;
    uint256 public totalEarned;
    
    uint256 public oneMonth;
    uint256 public twoMonths;
    uint256 public threeMonths;
    uint256 public sixMonths;
    uint256 public nineMonths;
    uint256 public tweleMonths;

    mapping (address => uint256) public tokenStaked;
    mapping (address => uint256) public stakedTerm;
    mapping (address => uint256) public tokenTime;

    constructor(address _plaasTokenContract, address _farmTokenAddress,address payable _ownerAddress) public Owned(_ownerAddress) {

    plaasTokenContract = _plaasTokenContract;
    walletFees = 0.1 ether;
    farmTokenAddress = _farmTokenAddress;
    wallet = _ownerAddress;
    minimumTokens = 10000 ether;
    maximumStake = 5000000 ether;
    
    oneMonth = 0.066 ether;
    twoMonths = 0.1335 ether;
    threeMonths = 0.265 ether;
    sixMonths = 0.483 ether;
    nineMonths = 0.53 ether;
    tweleMonths = 0.67 ether;

    }
  
    function displayParameters () external view returns (uint256,uint256,uint256,uint256) {
        
        return (totalStaked, totalEarned, minimumTokens, maximumStake); 
        
    }

    function stakingParam (address userAddress) external view returns (uint256,uint256) {
        
        return (stakedTerm[userAddress],
           tokenStaked[userAddress]);
    }

    function stakeTokens(uint256 amount, uint256 term) external payable returns (bool) {
       
       require( msg.value >= walletFees, "fees is less");
       require (tokenStaked[msg.sender] == 0, "you have already staked tokens");
       require(amount >= minimumTokens && amount <= maximumStake, "amount not in range");
       require (term == 1 ||  term == 2 ||term == 3 || term == 6 || term == 9 || term == 12);
       require(ERC20(plaasTokenContract).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       uint256 checkAllowance = ERC20(plaasTokenContract).allowance(msg.sender, address(this)); 
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(plaasTokenContract).transferFrom(msg.sender,address(this),amount),'transfer From failed');
       wallet.transfer(msg.value);

       tokenTime[msg.sender] = now;
       totalStaked = totalStaked.add(amount);

       if (term == 3) {
           stakedTerm[msg.sender] = 3;
           tokenStaked[msg.sender] = amount;
       } else if (term == 6) {
           stakedTerm[msg.sender] = 6;
           tokenStaked[msg.sender] = amount;
       } else if (term == 9) {
           stakedTerm[msg.sender] = 9;
           tokenStaked[msg.sender] = amount;
       } else if (term == 12){
           stakedTerm[msg.sender] = 12;
           tokenStaked[msg.sender] = amount;
       }else if (term == 1) {
           stakedTerm[msg.sender] = 1;
           tokenStaked[msg.sender] = amount;           
       }
        else if (term == 2) {
           stakedTerm[msg.sender] = 2;
           tokenStaked[msg.sender] = amount;           
       }
        return true;   
    } 

    function changeFees(uint256 amount) external onlyOwner returns (bool){
       
       walletFees = amount;
       
   }

    function changeWallet(address payable addressUser) external onlyOwner returns (bool){
       
       wallet = addressUser;
       
   }


    function setPercentage(uint256 one, uint256 two, uint256 three,uint256 six, uint256 nine, uint256 twelve ) external onlyOwner returns (bool){
    
    oneMonth = one;
    twoMonths = two;
    threeMonths = three;
    sixMonths = six;
    nineMonths = nine;
    tweleMonths = twelve;

       
   }

    function changeMinMax(uint256 _minimumTokens, uint256 _maxTokens) external onlyOwner returns (bool){
       
       minimumTokens = _minimumTokens;
       maximumStake = _maxTokens;
       
   }

    function claimableTokens (address user) external view returns (uint256) {
    
    require(tokenStaked[user] > 0);

    if(stakedTerm[user] == 1) {
        uint256 onePercent = tokenStaked[user].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(oneMonth);
        return tokenToSend;
    }
    else if (stakedTerm[user] == 2) {
        uint256 onePercent = tokenStaked[user].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(twoMonths);
        return tokenToSend;
    }
    else if (stakedTerm[user] == 3) {
        uint256 onePercent = tokenStaked[user].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(threeMonths);
        return tokenToSend;
    }
    else if (stakedTerm[user] == 6) {
        uint256 onePercent = tokenStaked[user].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(sixMonths);        
        return tokenToSend;
    }
    else if (stakedTerm[user] == 9) {
        uint256 onePercent = tokenStaked[user].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(nineMonths);        
        return tokenToSend;
    }
    else if (stakedTerm[user] == 12) {
        uint256 onePercent = tokenStaked[user].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(tweleMonths);        
        return tokenToSend;
    }
    
    }


   function claimPFarmTokens (bytes calldata valueInbytes) external payable returns (bool) {
       require( msg.value >= walletFees.mul(2), "fees is less");       
    require(tokenStaked[msg.sender] > 0);
           wallet.transfer(msg.value);
        ERC20(farmTokenAddress).burn(tokenStaked[msg.sender],valueInbytes);
    if(stakedTerm[msg.sender] == 1) {
        require(now >= tokenTime[msg.sender].add(30 days));//30 days

        uint256 onePercent = tokenStaked[msg.sender].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(oneMonth);

        totalEarned = totalEarned.add(tokenToSend);
        require(ERC20(farmTokenAddress).giveRewardsToStakers(msg.sender,tokenToSend));

           stakedTerm[msg.sender] = 0;
           tokenStaked[msg.sender] = 0;
           tokenTime[msg.sender] = 0;

    }
    else if (stakedTerm[msg.sender] == 2) {

        require(now >= tokenTime[msg.sender].add(60 days));//60 days

        uint256 onePercent = tokenStaked[msg.sender].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(twoMonths);

        totalEarned = totalEarned.add(tokenToSend);
        require(ERC20(farmTokenAddress).giveRewardsToStakers(msg.sender,tokenToSend));


           stakedTerm[msg.sender] = 0;
           tokenStaked[msg.sender] = 0;
           tokenTime[msg.sender] = 0;
        
    }
    else if (stakedTerm[msg.sender] == 3) {

        require(now >= tokenTime[msg.sender].add(90 days));//90 days

        uint256 onePercent = tokenStaked[msg.sender].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(threeMonths);  

        totalEarned = totalEarned.add(tokenToSend);
        require(ERC20(farmTokenAddress).giveRewardsToStakers(msg.sender,tokenToSend));


           stakedTerm[msg.sender] = 0;
           tokenStaked[msg.sender] = 0;
           tokenTime[msg.sender] = 0;

    }
    else if (stakedTerm[msg.sender] == 6) {
        require(now >= tokenTime[msg.sender].add(180 days));//180 days

        uint256 onePercent = tokenStaked[msg.sender].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(sixMonths);  

        totalEarned = totalEarned.add(tokenToSend);
        require(ERC20(farmTokenAddress).giveRewardsToStakers(msg.sender,tokenToSend));

           stakedTerm[msg.sender] = 0;
           tokenStaked[msg.sender] = 0;
           tokenTime[msg.sender] = 0;

    }
       
    else if (stakedTerm[msg.sender] == 9) {
        require(now >= tokenTime[msg.sender].add(270 days));//270 days
        uint256 onePercent = tokenStaked[msg.sender].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(nineMonths);  
        totalEarned = totalEarned.add(tokenToSend);
        require(ERC20(farmTokenAddress).giveRewardsToStakers(msg.sender,tokenToSend));

           stakedTerm[msg.sender] = 0;
           tokenStaked[msg.sender] = 0;
           tokenTime[msg.sender] = 0;

    }

    else if (stakedTerm[msg.sender] == 12) {

        require(now >= tokenTime[msg.sender].add(360 days));//360 days

        uint256 onePercent = tokenStaked[msg.sender].div(10000 ether);
        uint256 tokenToSend = onePercent.mul(nineMonths);  

        totalEarned = totalEarned.add(tokenToSend);
        require(ERC20(farmTokenAddress).giveRewardsToStakers(msg.sender,tokenToSend));

           stakedTerm[msg.sender] = 0;
           tokenStaked[msg.sender] = 0;
           tokenTime[msg.sender] = 0;

    }

   }

   function transferAnyERC20Token(address tokenAddress, uint tokens) external whenNotPaused onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        return ERC20(tokenAddress).transfer(owner, tokens);
    }}