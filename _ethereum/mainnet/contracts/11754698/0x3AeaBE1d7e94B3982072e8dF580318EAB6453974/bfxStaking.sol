pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Owned is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function mint(address account, uint256 amount) external;
  function burn(uint256 amount) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract bfxStaking is Owned {
  using SafeMath for uint256;

  event userStakeEvent(
      address account,
      uint256 amount
  );
  event userUnStakeEvent(
      address account,
      uint256 amount
  );
  event userClaimEvent(
      address account,
      address token,
      uint256 amount
  );
  event rewardPoolTopupEvent(
      address tokenAddress,
      uint256 amount
  );

  IERC20 public bfxTKN;

  struct userStakeStruct {
    uint256 bfx;
    mapping(address => uint) PoolAtEntry;
  }
  
  uint256 public bfxTotal;

  bool public stakingActive;

  mapping(address => userStakeStruct) public userStake;
  
  receive() external payable {
        rewardPool[address(0)] = rewardPool[address(0)].add(msg.value);
        emit rewardPoolTopupEvent(
          address(0),
          msg.value
        );
  }
  //////////////////////////////
  // Reward ETH or ERC20 tokens
  // ETH is address(0)
  //////////////////////////////
  struct tokens{
      string name;
      address tokenAddress;
      bool status;
  }
  mapping(uint => tokens) public tokenList;
  uint public tokenCount;
  
  mapping(address => uint) public rewardPool;
  
  constructor() public {
    stakingActive = true;
    bfxTKN = IERC20(0x25901F2a5A4bb0aaAbe2CDb24E0E15A0d49B015d);
    tk_addTokenList("ETH",address(0));
    tk_addTokenList("USDT",address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
  }
  
  function tk_topUpRewardPool(address _ERC20TokenAddress,uint _amount) public {
        require(_amount > 0);
        uint allowance = IERC20(_ERC20TokenAddress).allowance(msg.sender, address(this));
        require(allowance >= _amount);
        require(IERC20(_ERC20TokenAddress).transferFrom(msg.sender, address(this), _amount));
        
        rewardPool[_ERC20TokenAddress] = rewardPool[_ERC20TokenAddress].add(_amount);
        emit rewardPoolTopupEvent(
          _ERC20TokenAddress,
          _amount
        );
  }
  function tk_topUpETHRewardPool() payable public {
        require(msg.value > 0);
       
        rewardPool[address(0)] = rewardPool[address(0)].add(msg.value);
        emit rewardPoolTopupEvent(
          address(0),
          msg.value
        );
  }
  function tk_getPoolAtEntry(address user,address token) public view returns(uint){
      return userStake[user].PoolAtEntry[token];
  }
  function tk_getReward(address user, address token) public view returns(uint){
      if (bfxTotal == 0 ) return 0;
      return (rewardPool[token] - userStake[user].PoolAtEntry[token]).mul(userStake[user].bfx).div(bfxTotal);
  }
  function tk_claimReward(address token) public {
      require(stakingActive,'contract not active');
      if (bfxTotal == 0 ) return;
      uint reward = tk_getReward(msg.sender,token);
      if (reward == 0) return;
      userStake[msg.sender].PoolAtEntry[token] = rewardPool[token];
      if (token != address(0))
        require(IERC20(token).transfer(msg.sender,reward));
      else
        require(msg.sender.send(reward));
      emit userClaimEvent(msg.sender,token,reward);
  }
  function tk_addTokenList(string memory name,address _tokenAddress) onlyOwner public  {
      tokenCount++;
      tokenList[tokenCount].tokenAddress = _tokenAddress;
      tokenList[tokenCount].status = true;
      tokenList[tokenCount].name = name;
  }
  function tk_setTokenStatus(uint index,bool _status) onlyOwner public  {
      require(index<=tokenCount);
      tokenList[index].status = _status;
  }
  function tk_resetTokenList() onlyOwner public  {
      tokenCount = 0;
  }
  function resetPoolAtEntry() private {
      for (uint i=1;i<=tokenCount;i++){
          if (tokenList[i].status){
              userStake[msg.sender].PoolAtEntry[tokenList[i].tokenAddress] = rewardPool[tokenList[i].tokenAddress];
          }
      }
  }
  
  function stake(uint256 amount) public {
    require(stakingActive,'contract not active');
    require(bfxTKN.transferFrom(msg.sender, address(this), amount));
    userStake[msg.sender].bfx = userStake[msg.sender].bfx.add(amount);
    
    bfxTotal = bfxTotal.add(amount);
    resetPoolAtEntry();
    emit userStakeEvent(msg.sender, amount);
  }

  function unstake(uint256 amount) public {
    require(stakingActive,'contract not active');
    require(userStake[msg.sender].bfx >= amount);
    
    userStake[msg.sender].bfx = userStake[msg.sender].bfx.sub(amount);
    bfxTotal = bfxTotal.sub(amount);
    require(bfxTKN.transfer(msg.sender, amount));
    resetPoolAtEntry();
    emit userUnStakeEvent(msg.sender, amount);
  }
  
  function transferFund(address ERC20token,uint256 amount,address receiver) onlyOwner public {
    uint256 balance = IERC20(ERC20token).balanceOf(address(this));
    require(amount<=balance,'exceed contract balance');
    IERC20(ERC20token).transfer(receiver, amount);
  }
  function transferFundETH(uint256 amount,address payable receiver) onlyOwner public {
    uint256 balance = address(this).balance;
    require(amount<=balance,'exceed contract balance');
    receiver.transfer(amount);
  }
  
  function setStakingStatus(bool status) public onlyOwner() {
    stakingActive = status;
  }

}