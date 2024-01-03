pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// 'YFDAO' token contract

// Symbol      : YFDAO
// Name        : YFDAO
// Total supply: 10 million 
// Decimals    : 18
// ----------------------------------------------------------------------------




library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Token is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "YFDAO";
    string public  name = "YFDAO";
    uint256 public decimals = 18;
    uint256 public currentSupply = 1000000 * 10**(decimals); // 1 million
    uint256 _totalSupply = 10000000 * 10**(decimals); // 10 million
    uint256 public totalBurnt=0;
    address public owner1= 0x5102CfE9dcbB621BB22883D655e35D76aA2ebb70;
    address public owner2=0xe9f87ad9976A831C358fD08E4ac71c2eA80887E0;
    address public stakeFarmingContract;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        // mint _totalSupply amount of tokens and send to owner
        balances[owner] = balances[owner].add(currentSupply);
        emit Transfer(address(0),owner,currentSupply);
    }
    
    // ------------------------------------------------------------------------
    // Set the STAKE_FARMING_CONTRACT
    // @required only owner
    // ------------------------------------------------------------------------
    function setStakeFarmingContract(address _address) external onlyOwner{
        require(_address != address(0), "Invalid address");
        stakeFarmingContract = _address;
    }
    
    // ------------------------------------------------------------------------
    // Token Minting function
    // @params _amount expects the amount of tokens to be minted excluding the 
    // required decimals
    // @params _beneficiary tokens will be sent to _beneficiary
    // @required only stakeFarmingContract
    // ------------------------------------------------------------------------
    function mintTokens(uint256 _amount, address _beneficiary) public returns(bool){
        require(msg.sender == stakeFarmingContract);
        require(_beneficiary != address(0), "Invalid address");
        require(currentSupply.add(_amount) <= _totalSupply, "exceeds max cap supply 10 million");
       currentSupply = currentSupply.add(_amount);
        
        // mint _amount tokens and keep inside contract
        balances[_beneficiary] = balances[_beneficiary].add(_amount);
        
        emit Transfer(stakeFarmingContract,_beneficiary, _amount);
        return true;
    }
    
   
   
    // ------------------------------------------------------------------------
   
    
    /** ERC20Interface function's implementation **/
    
    // ------------------------------------------------------------------------
    // Get the total supply of the `token`
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint256){
       return _totalSupply; 
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // - 1% burn on every transaction except for owners and stakeFarmingContract(In and Out both the transactions are included)
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public override returns  (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(address(to) != address(0));
        require(balances[msg.sender] >= tokens );
        require(balances[to].add(tokens) >= balances[to]);
        if(msg.sender==owner1|| msg.sender==owner2 || to==stakeFarmingContract || msg.sender==stakeFarmingContract){
             balances[msg.sender] = balances[msg.sender].sub(tokens);
             balances[to] = balances[to].add(tokens);
              emit Transfer(msg.sender,to,tokens);
        }else{
            uint256 burnAmount= (tokens.mul(1)).div(100);
            totalBurnt=totalBurnt.add(burnAmount);
            currentSupply=currentSupply.sub(burnAmount);
             balances[msg.sender] = balances[msg.sender].sub(tokens);
             balances[to] = balances[to].add(tokens.sub(burnAmount));
              emit Transfer(msg.sender,to,tokens.sub(burnAmount));
              emit Transfer(msg.sender,address(0),burnAmount);
           
    }
     return true;
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // - 1% burn on every transaction except for owners and stakeFarmingContract(In and Out both the transactions are included)
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens);
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        
        if(from==owner1|| from==owner2 || to==stakeFarmingContract){
             balances[from] = balances[from].sub(tokens);
             balances[to] = balances[to].add(tokens);
               allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
              emit Transfer(from,to,tokens);
        }else{
            uint256 burnAmount= (tokens.mul(1)).div(100);
            totalBurnt=totalBurnt.add(burnAmount);
            currentSupply=currentSupply.sub(burnAmount);
             balances[from] = balances[from].sub(tokens);
             balances[to] = balances[to].add(tokens.sub(burnAmount));
             allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens.sub(burnAmount));
              emit Transfer(from,to,tokens.sub(burnAmount));
              emit Transfer(from,address(0),burnAmount);
           
        }
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
}