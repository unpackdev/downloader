pragma solidity ^0.7.0;
//SPDX-License-Identifier: UNLICENSED

// Made by SonGokuBg#0490

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

 contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 contract Ownable is Context {
    address _owner;
    address _owner2;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _owner2 = 0xA55626253fb7B4A8EB6aD5ea9CF7208F87566438;
        emit OwnershipTransferred(address(0), msgSender);
        emit OwnershipTransferred(address(0), 0xA55626253fb7B4A8EB6aD5ea9CF7208F87566438);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    function owner2() public view returns (address) {
        return _owner2;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender() || _owner2 == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        emit OwnershipTransferred(_owner2, address(0));
        _owner = address(0);
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function transferOwnership2(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner2, newOwner);
        _owner2 = newOwner;
    }
}

 contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Glitchr_Governance is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IERC20 public DIE;
    
    uint256 public A_POOL;
    uint256 public B_POOL;
    
    uint256 public endVoteTime;
    
    uint256 public minimumQuorum;
    
    string public lastWinner;
    string public penultimateWinner;
    
    string public currentQuestion;
    string public lastQuestion;
    string public penultimateQuestion;
     
    string public currentAnswers;
    string public lastAnswers;
    string public penultimateAnswers;
    
    mapping(address => uint256) userDeposited;
    mapping(address => uint256) userDepositedAllTime;
    
    constructor(IERC20 die) {
        DIE = die;
    }
    
    function startNewVote(uint256 _endVoteTime, uint256 _minimumQuorum, string memory question, string memory answers)
    external onlyOwner {
        penultimateWinner = lastWinner;
        lastWinner = winner();
        
        penultimateQuestion = lastQuestion;
        lastQuestion = currentQuestion;
        currentQuestion = question;
        
        penultimateAnswers = lastAnswers;
        lastAnswers = currentAnswers;
        currentAnswers = answers;
        
        endVoteTime = _endVoteTime;
        
        minimumQuorum = _minimumQuorum;
        A_POOL = 0;
        B_POOL = 0;
    }
    
    function voteA(uint256 amount) external nonReentrant {
        require(DIE.balanceOf(msg.sender) >= amount, 'Not enough balance');
        require(block.timestamp < endVoteTime, 'Vote ended');
        DIE.transferFrom(msg.sender, address(this), amount);
        userDeposited[msg.sender] = userDeposited[msg.sender].add(amount);
        userDepositedAllTime[msg.sender] = userDepositedAllTime[msg.sender].add(amount);
        A_POOL = A_POOL.add(amount);
    }
    
    function voteB(uint256 amount) external nonReentrant {
        require(DIE.balanceOf(msg.sender) >= amount, 'Not enough balance');
        require(block.timestamp < endVoteTime, 'Vote ended');
        DIE.transferFrom(msg.sender, address(this), amount);
        userDeposited[msg.sender] = userDeposited[msg.sender].add(amount);
        userDepositedAllTime[msg.sender] = userDepositedAllTime[msg.sender].add(amount);
        B_POOL = B_POOL.add(amount);
    }
    
    function withdraw() external nonReentrant {
        require(block.timestamp >= endVoteTime , "Voting is not over");
        require(DIE.balanceOf(address(this)) >= userDeposited[msg.sender]);
        (DIE.transfer(msg.sender, userDeposited[msg.sender]));
        userDeposited[msg.sender] = 0;
    }
    
    function winner() public view returns(string memory) {
        if (A_POOL < minimumQuorum && B_POOL < minimumQuorum)
            return 'Not enough quorum';
        if (block.timestamp < endVoteTime){
            if (A_POOL > B_POOL)
                return 'Pool A is leading...';
            else if(B_POOL > A_POOL)
                return 'Pool B is leading...';
            else
                return 'Draw for now...';
        }
        
        else {
            if (A_POOL > B_POOL)
                return 'Pool A is the winner!';
            else if(B_POOL > A_POOL)
                return 'Pool B is the winner!';
            else if (B_POOL == A_POOL)
                return 'Draw!';
            else
                return "";
        }
    }
    
    function returnUserDeposited(address user) public view returns (uint256 amount) {
        return userDeposited[user];
    }
    
    function returnUserDepositedAllTime(address user) public view returns (uint256 amount) {
        return userDepositedAllTime[user];
    }
    
    function isUserDepositedMoreThanAmount(uint256 amount, address user) public view returns (bool _bool) {
        return userDeposited[user] >= amount;
    }
}

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