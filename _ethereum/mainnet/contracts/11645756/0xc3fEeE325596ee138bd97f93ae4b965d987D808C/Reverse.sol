/**
 *Submitted for verification at Etherscan.io on 2020-12-17
*/

pragma solidity 0.4.24;

//Social Media Links
//Website : https://reverseprotocol.org
//Telegram : t.me/reverseprotocol
//Twitter :https://twitter.com/reverseprotocol
//Medium : https://medium.com/@reverseprotocol
 
contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  function isConstructor() private view returns (bool) {
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  uint256[50] private ______gap;
}

contract Ownable is Initializable {

  address private _owner;
  uint256 private _ownershipLocked;

  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  function initialize(address sender) internal initializer {
    _owner = sender;
	_ownershipLocked = 0;
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
  // Set _ownershipLocked flag to lock contract owner forever
  function lockOwnership() public onlyOwner {
	require(_ownershipLocked == 0);
	emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private ______gap;
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string name, string symbol, uint8 decimals) internal initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string) {
    return _name;
  }

  function symbol() public view returns(string) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface UNIV2Sync {
    function sync() external;
}

interface RapidsSync {
    function syncrapids() external;
}

contract Reverse is ERC20Detailed, Ownable {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of gons that equals 1 fragment.
    //    The inverse rate must not be used--TOTAL_GONS is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert gons to fragments instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Gon balances converted into Fragments are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
    //   be decreased by precisely x Fragments, and B's external balance will be precisely
    //   increased by x Fragments.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;
    
    
      struct MagicBlocks {
      
         uint delayend; // receivers + lock
      
    }
    

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    
   
    mapping (address => MagicBlocks) public MagicBlocksMap;
    uint Magiclock = 20;
    bool public Magic = false;
    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 578107661777206; //old MibASE supply

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    uint256 maxDebase=9000;
    
    IERC20 REBASETOKEN;
    address RapiDsaddress;
    address UNISWAPPAIRaddress;
    address DAOVotesaddress;
    address UniswapRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    uint256 public lastTrackedReBaseSupply;
    bool public baseSupplyHasBeenInitilized = false;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;
    
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    //event NewMagiclock(address receivers, uint delayend);
    
     function setDAOvotecontract (address _daovote) onlyOwner public {
        DAOVotesaddress = _daovote;
        
    }
    
    function setREBASEcontract (IERC20 _rebasetoken)  public {
        require(msg.sender == DAOVotesaddress, "!governance");
        REBASETOKEN = _rebasetoken;
        lastTrackedReBaseSupply = REBASETOKEN.totalSupply();
         baseSupplyHasBeenInitilized = true;
    }
   
    
    function setUNISWAPPAIRcontract (IERC20 _unipair) onlyOwner public {
        UNISWAPPAIRaddress = _unipair;

    }
    function setRAPIDScontract (IERC20 _rapids) onlyOwner public {
        RapiDsaddress = _rapids;
        
    }
    
     function setMAXdebase (uint256 _maxdebase) onlyOwner public {
        maxDebase = _maxdebase;
    }
    
      uint public MagicEND;
      uint  MagicSTART=172800;
    
    function initializeMagic() onlyOwner public {
     require(Magic==false,"Magic Already Actived");
        MagicEND =block.number.add(MagicSTART) ;
         Magic = true;
    }
    
    
    
    
    function nextRebaseInfo()
        external view
        returns (uint256, bool)
    {
        uint256 baseTotalSupply = REBASETOKEN.totalSupply();
        uint256 multiplier;
       
        
        
        bool rebaseIsPositive = false;
        if (baseTotalSupply > lastTrackedReBaseSupply) {
            
           multiplier = (baseTotalSupply.sub(lastTrackedReBaseSupply)).mul(10000).div(lastTrackedReBaseSupply);
           if(multiplier >= 10000){
               multiplier= maxDebase;
           }
            
        } else if (lastTrackedReBaseSupply > baseTotalSupply) {
        
         multiplier = (lastTrackedReBaseSupply.sub(baseTotalSupply)).mul(10000).div(lastTrackedReBaseSupply).mul(2);
           
            rebaseIsPositive = true;
        }

        return (multiplier, rebaseIsPositive);
    }

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase()
        external
        returns (uint256)
    {
        
        uint256 baseTotalSupply = REBASETOKEN.totalSupply();
        uint256 multiplier;
        
         
       
        require(baseTotalSupply != lastTrackedReBaseSupply, 'NOT YET PLEASE WAIT');
        
        
         if(block.number >= MagicEND){
              Magic = false;
         }
        
        if (baseTotalSupply > lastTrackedReBaseSupply) {
            
              multiplier = (baseTotalSupply.sub(lastTrackedReBaseSupply)).mul(10000).div(lastTrackedReBaseSupply);
              
               if(multiplier >= maxDebase){
               multiplier= maxDebase;
           }
            
        } else if (lastTrackedReBaseSupply > baseTotalSupply) {
            
            multiplier = (lastTrackedReBaseSupply.sub(baseTotalSupply)).mul(10000).div(lastTrackedReBaseSupply).mul(2);
        }
        
        uint256 modification;
        modification = _totalSupply.mul(multiplier).div(10000);
        if (baseTotalSupply > lastTrackedReBaseSupply) {
            _totalSupply = _totalSupply.sub(modification);
           
        } else {
            _totalSupply = _totalSupply.add(modification);
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        
        lastTrackedReBaseSupply = baseTotalSupply;

    
    UNIV2Sync(UNISWAPPAIRaddress).sync();
    RapidsSync(RapiDsaddress).syncrapids();
    
    

        emit LogRebase(block.timestamp, _totalSupply);
        return _totalSupply;
        
   
    }
    
    constructor() public {
		Ownable.initialize(msg.sender);
		ERC20Detailed.initialize("Reverse  Protocol", "Reverse", uint8(DECIMALS));
        
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * @return The total number of fragments.
     */
     
      function ViewRebaseTarget()
        public
        view
        returns (address)
    {
        return REBASETOKEN;
    } 
     function ViewDAOVotesaddress()
        public
        view
        returns (address)
    {
        return DAOVotesaddress;
    } 
    
     function ViewRapiDsaddress()
        public
        view
        returns (address)
    {
        return RapiDsaddress;
    }
    
    function ViewUNISWAPaddress()
        public
        view
        returns (address)
    {
        return UNISWAPPAIRaddress;
    }
    function ViewMagicblock(address _receivers)
        public
        view
        returns (bool)
    {
       if(block.number >= MagicBlocksMap[_receivers].delayend){
       return true;
       }else {
            return false;
       }
    }
     
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        validRecipient(to)
        
        returns (bool)
    {
        
        
        if(Magic==true){
            
            
              if(ViewMagicblock(msg.sender)!=true){
             revert("You cant send before Magiclock");
       }
        
        if(to != UNISWAPPAIRaddress && to != UniswapRouter && to != RapiDsaddress){
       
        MagicBlocksMap[to].delayend=Magiclock.add(block.number);
        
                }
        
        }
        
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)
        
        returns (bool)
    {
    
        if(Magic==true){
            
      
       if(ViewMagicblock(from)!=true){
             revert("You cant send before Magiclock");
       }
        
        if(to != UNISWAPPAIRaddress && to != UniswapRouter && to != RapiDsaddress){
        MagicBlocksMap[to].delayend=Magiclock.add(block.number);
        
                }
        
        }
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);
      // emit NewMagiclock(to,delayend);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}