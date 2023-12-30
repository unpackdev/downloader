pragma solidity ^0.7.0;

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract KimbapHodl {
    
    using SafeMath for uint256;
    
    event Deposit(address indexed hodler, address token, uint256 amount, uint letGoTime);
    event Claim(address indexed hodler, address token, uint256 amount, uint claimTime);
    event PanicClaim(address indexed hodler, address token, uint256 amount, uint claimTime);
    
    struct TokenHodling {
        uint256 tokenAmount;
        uint256 depositTime;
        uint256 letGoTime;
        bool claimed;
        uint256 rewardsIssued;
    }
    
    address payable public owner;
    
    mapping(address => mapping(address => TokenHodling[])) public hodlers;
    address public kimbapAddress;
    IERC20 public kimbapToken;
    
    uint256 public rewardsPerBlock;
    uint256 public kimbapDepositPayment;
    uint256 public kimbapPanicClaimPenalty;
    
    mapping (address => bool) public tokenWhitelist;
    bool useWhitelist;
    
    constructor() {
        owner = msg.sender;
        kimbapAddress = 0xa9af9CB36d7FCBB21149628BDF76Cc8Aa8987FA5;
        kimbapToken = IERC20(kimbapAddress);
        kimbapPanicClaimPenalty = 1000000000000000000000;
        useWhitelist = false;
    }
    
    function deposit(address tokenAddress, uint256 tokenAmount, uint256 letGoTime) external {
        require(tokenAmount > 0, "Deposit amount cannot be 0.");
        require(letGoTime > block.timestamp, "Time to claim must be in the future.");
        
        if (useWhitelist == true) {
            require(tokenWhitelist[tokenAddress] == true, "Token is not whitelisted.");
        }
        
        if (kimbapDepositPayment > 0) {
            uint256 kimbapBalance = kimbapToken.balanceOf(msg.sender);
            require(kimbapBalance >= kimbapDepositPayment, "Insufficient KIMBAP for payment.");
            kimbapToken.transferFrom(msg.sender, address(this), kimbapDepositPayment);
        }
        
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        hodlers[msg.sender][tokenAddress].push(TokenHodling(tokenAmount, block.timestamp, letGoTime, false, 0));
        emit Deposit(msg.sender, tokenAddress, tokenAmount, letGoTime);
    }
    
    function claim(address tokenAddress, uint256 depositSlot) external {
        TokenHodling memory hodling = hodlers[msg.sender][tokenAddress][depositSlot];
        require(block.timestamp > hodling.letGoTime, "Not time to sell yet!");
        require(hodling.claimed != true, "Already claimed!");
        
        uint256 kimbapRewards = (block.timestamp.sub(hodling.depositTime)).mul(rewardsPerBlock);
        uint256 hodlKimbapBalance = kimbapToken.balanceOf(address(this));
        
        if (hodlKimbapBalance > kimbapRewards) {
            kimbapToken.transfer(msg.sender, kimbapRewards);
        }
        else {
            kimbapToken.transfer(msg.sender, hodlKimbapBalance);
        }
        
        hodlers[msg.sender][tokenAddress][depositSlot].claimed = true;
        hodlers[msg.sender][tokenAddress][depositSlot].rewardsIssued = kimbapRewards;
        IERC20(tokenAddress).transfer(msg.sender, hodling.tokenAmount);
        emit Claim(msg.sender, tokenAddress, hodling.tokenAmount, block.timestamp);
    }
    
    function panicClaim(address tokenAddress, uint256 depositSlot) external {
        TokenHodling memory hodling = hodlers[msg.sender][tokenAddress][depositSlot];
        require(hodling.claimed != true, "Already claimed!");
        
        if (kimbapPanicClaimPenalty > 0) {
            uint256 kimbapBalance = kimbapToken.balanceOf(msg.sender);
            require(kimbapBalance >= kimbapPanicClaimPenalty, "Insufficient KIMBAP for penalty payment.");
            kimbapToken.transferFrom(msg.sender, address(this), kimbapPanicClaimPenalty);
        }
        
        hodlers[msg.sender][tokenAddress][depositSlot].claimed = true;
        IERC20(tokenAddress).transfer(msg.sender, hodling.tokenAmount);
        emit PanicClaim(msg.sender, tokenAddress, hodling.tokenAmount, block.timestamp);
    }
    
    function setRewardsPerBlock(uint256 _rewardsPerBlock) external isOwner {
        rewardsPerBlock = _rewardsPerBlock;
    }
    
    function setKimbapDepositPayment(uint256 _kimbapDepositPayment) external isOwner {
        kimbapDepositPayment = _kimbapDepositPayment;
    }
    
    function setKimbapPanicClaimPenalty(uint256 _kimbapPanicClaimPenalty) external isOwner {
        kimbapPanicClaimPenalty = _kimbapPanicClaimPenalty;
    }
    
    function addTokenToWhitelist(address token) public isOwner {
        tokenWhitelist[token] = true;
    }
    
    function removeTokenFromWhitelist(address token) public isOwner {
        tokenWhitelist[token] = false;
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    function changeOwner(address payable newOwner) external isOwner {
        owner = newOwner;
    }
}