/*
Website: Wish.Finance

DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFFFFFFFFIIIIIIIIII
D::::::::::::DDD   E::::::::::::::::::::EF::::::::::::::::::::FI::::::::I
D:::::::::::::::DD E::::::::::::::::::::EF::::::::::::::::::::FI::::::::I
DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::EFF::::::FFFFFFFFF::::FII::::::II
D:::::D    D:::::D E:::::E       EEEEEE  F:::::F       FFFFFF  I::::I  
D:::::D     D:::::DE:::::E               F:::::F               I::::I  
D:::::D     D:::::DE::::::EEEEEEEEEE     F::::::FFFFFFFFFF     I::::I  
D:::::D     D:::::DE:::::::::::::::E     F:::::::::::::::F     I::::I  
D:::::D     D:::::DE:::::::::::::::E     F:::::::::::::::F     I::::I  
D:::::D     D:::::DE::::::EEEEEEEEEE     F::::::FFFFFFFFFF     I::::I  
D:::::D     D:::::DE:::::E               F:::::F               I::::I  
D:::::D    D:::::D E:::::E       EEEEEE  F:::::F               I::::I  
DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::EFF:::::::FF           II::::::II
D:::::::::::::::DD E::::::::::::::::::::EF::::::::FF           I::::::::I
D::::::::::::DDD   E::::::::::::::::::::EF::::::::FF           I::::::::I
DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFF           IIIIIIIIII
                                                                                                                                                                                      
                                                         
Wish.Finance Staking and Farming Token
*/

pragma solidity 0.4.26;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}


// Wish token


contract Wish is ERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;
  string public constant name  = "Wish Finance";
  string public constant symbol = "Wish";
  uint8 public constant decimals = 18;

  uint256 _totalSupply = 50000 * (10 ** 18);
  uint256 public totalBurned = 0;

  //nonstandard variables
  mapping(address=>bool) public burnExempt;
  uint256 public TOKEN_BURN_RATE = 50; //represents 5%, shows 50 so that it may be adjusted to decimal precision
  bool public burnActive=true; //once turned off burn on transfer is permanently disabled
  uint256 LOCKED_AMOUNT=5000 * (10 ** 18);
  uint256 unlockTime=now + 60 days;

  constructor() public Ownable(){
    balances[address(this)] = LOCKED_AMOUNT;
    uint amountRemaining = _totalSupply.sub(LOCKED_AMOUNT);
    balances[msg.sender] = amountRemaining;
    emit Transfer(address(0), address(this), LOCKED_AMOUNT);
    emit Transfer(address(0), msg.sender, amountRemaining);
  }
  function addBurnExempt(address addr) public onlyOwner{
    burnExempt[addr]=true;
  }
  function removeBurnExempt(address addr) public onlyOwner{
    burnExempt[addr]=false;
  }
  function permanentlyDisableBurnOnTransfer() public onlyOwner{
    burnActive=false;
  }
  /*
    After 2 months team can retrieve locked tokens
  */
  function retrieveLockedAmount(address to) public onlyOwner{
    require(now>unlockTime);
    uint256 toRetrieve = balances[address(this)];
    balances[to] = balances[to].add(toRetrieve);
    balances[address(this)] = 0;
    emit Transfer(address(this), to, toRetrieve);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address user) public view returns (uint256) {
    return balances[user];
  }

  function allowance(address user, address spender) public view returns (uint256) {
    return allowed[user][spender];
  }

  function transfer(address recipient, uint256 value) public returns (bool) {
    require(value <= balances[msg.sender]);
    require(recipient != address(0));

    uint burnFee;
    if((!burnActive)||burnExempt[msg.sender]){
      burnFee=0;
    }
    else{
      burnFee=value.mul(TOKEN_BURN_RATE).div(1000);
    }
    uint256 tokensToTransfer = value.sub(burnFee);

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[recipient] = balances[recipient].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(burnFee);
    totalBurned = totalBurned.add(burnFee);

    emit Transfer(msg.sender, recipient, tokensToTransfer);
    if(burnFee>0){
      emit Transfer(msg.sender, address(0), burnFee);
    }
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
    return true;
  }

  function transferFrom(address from, address recipient, uint256 value) public returns (bool) {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(recipient != address(0));

    uint burnFee;
    if((!burnActive)||burnExempt[from]||burnExempt[msg.sender]){
      burnFee=0;
    }
    else{
      burnFee=value.mul(TOKEN_BURN_RATE).div(1000);
    }
    uint256 tokensToTransfer = value.sub(burnFee);

    balances[from] = balances[from].sub(value);
    balances[recipient] = balances[recipient].add(tokensToTransfer);

    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

    _totalSupply = _totalSupply.sub(burnFee);
    totalBurned = totalBurned.add(burnFee);

    emit Transfer(from, recipient, tokensToTransfer);
    if(burnFee>0){
      emit Transfer(msg.sender, address(0), burnFee);
    }

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function burn(uint256 amount) public {
    require(amount != 0);
    require(amount <= balances[msg.sender]);
    totalBurned = totalBurned.add(amount);
    _totalSupply = _totalSupply.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }

}