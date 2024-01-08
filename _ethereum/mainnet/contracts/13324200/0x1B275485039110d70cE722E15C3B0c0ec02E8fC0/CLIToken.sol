// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;

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
library SafeMath
{

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    	{
		uint256 c = a * b;
		assert(a == 0 || c / a == b);

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
  	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a / b;

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
  	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);

		return a - b;
  	}

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
  	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);

		return c;
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
contract OwnerHelper
{
  	address public owner;

  	event ChangeOwner(address indexed _from, address indexed _to);

    /**
     * @dev Throws if called by any account other than the owner.
     */
  	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
  	}
  	
  	constructor() public
	{
		owner = msg.sender;
  	}

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */  	
  	function transferOwnership(address _to) onlyOwner public
  	{
    	require(_to != owner);
    	require(_to != address(0x0));

        address from = owner;
      	owner = _to;
  	    
      	emit ChangeOwner(from, _to);
  	}
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() view public returns (uint _supply);
    function balanceOf( address _who ) public view returns (uint _value);
    function transfer( address _to, uint _value) public returns (bool _success);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) public view returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

// Top Module
contract CLIToken is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    
    // Total                                  2,000,000,000
    uint constant public maxTotalSupply     = 2000000000 * E18;

    // User Engagement                        1,000,000,000 (50%)
    uint constant public maxUserSupply      = 1000000000 * E18;

    // ECO System                             400,000,000 (20%)
    uint constant public maxECOSupply       = 400000000 * E18;

    // Airdrop                                200,000,000 (10%)
    uint constant public maxAirdropSupply   = 200000000 * E18;

    // Marketing                              200,000,000 (10%)
    uint constant public maxMarketSupply    = 200000000 * E18;

    // Research & Development                 100,000,000 (5%)
    uint constant public maxRnDSupply       = 100000000 * E18;

    // Team                                   50,000,000 (2.5%)
    uint constant public maxTeamSupply      = 50000000 * E18;

    // Reserve                                50,000,000 (2.5%)
    uint constant public maxReserveSupply   = 50000000 * E18;   
        

    uint public totalTokenSupply;

    uint public tokenIssuedUser;
    uint public tokenIssuedECO;
    uint public tokenIssuedAirdrop;
    uint public tokenIssuedMarket;
    uint public tokenIssuedRnD;
    uint public tokenIssuedTeam;
    uint public tokenIssuedReserve;    
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
      
    bool public tokenLock = false;


    event UserIssue(address indexed _to, uint _tokens);
    event ECOIssue(address indexed _to, uint _tokens);
    event AirdropIssue(address indexed _to, uint _tokens);
    event MarketIssue(address indexed _to, uint _tokens);
    event RnDIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event ReserveIssue(address indexed _to, uint _tokens);

    // Construction of CLI
    constructor() public {
        name        = "CatchLive";
        decimals    = 18;
        symbol      = "CLI";
        
        totalTokenSupply = 0;
        balances[owner] = totalTokenSupply;

        // Token Issue
        tokenIssuedUser     = 0;
        tokenIssuedECO      = 0;
        tokenIssuedAirdrop  = 0;
        tokenIssuedMarket   = 0;
        tokenIssuedRnD      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedReserve  = 0;
        
        // Check max supply
        require(maxTotalSupply == maxUserSupply + maxECOSupply + maxAirdropSupply + maxMarketSupply + maxRnDSupply + maxTeamSupply + maxReserveSupply);
    }

    // ERC20 totalSupply
    function totalSupply() view public returns (uint) {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) view public returns (uint) {
        return balances[_who];
    }
    
    // ERC20 transfer
    function transfer(address _to, uint _value) public returns (bool) {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    // ERC20 approve
    function approve(address _spender, uint _value) public returns (bool) {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        approvals[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true; 
    }
    
    // ERC20 allowance
    function allowance(address _owner, address _spender) view public returns (uint) {
        return approvals[_owner][_spender];
    }

    // ERC20 transferFrom
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(isTransferable() == true);
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    // Issue for User engagement
    function userIssue(address _to) onlyOwner public {
        require(tokenIssuedUser == 0);
        
        uint tokens = maxUserSupply;

        balances[_to] = balances[_to].add(tokens);
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedUser = tokenIssuedUser.add(tokens);
        
        emit UserIssue(_to, tokens);
    }

    // Issue for ECO
    function ecoIssue(address _to) onlyOwner public {
        require(tokenIssuedECO == 0);
        
        uint tokens = maxECOSupply;

        balances[_to] = balances[_to].add(tokens);
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedECO = tokenIssuedECO.add(tokens);
        
        emit ECOIssue(_to, tokens);
    }

    // Issue for Airdrop
    function airdropIssue(address _to) onlyOwner public {
        require(tokenIssuedAirdrop == 0);
        
        uint tokens = maxAirdropSupply;

        balances[_to] = balances[_to].add(tokens);
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedAirdrop = tokenIssuedAirdrop.add(tokens);
        
        emit AirdropIssue(_to, tokens);
    }

    // Issue for Marketing
    function marketIssue(address _to) onlyOwner public {
        require(tokenIssuedMarket == 0);
        
        uint tokens = maxMarketSupply;

        balances[_to] = balances[_to].add(tokens);
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedMarket = tokenIssuedMarket.add(tokens);
        
        emit MarketIssue(_to, tokens);
    }    

    // Issue for Research and Development
    function rndIssue(address _to) onlyOwner public {
        require(tokenIssuedRnD == 0);
        
        uint tokens = maxRnDSupply;

        balances[_to] = balances[_to].add(tokens);
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedRnD = tokenIssuedRnD.add(tokens);
        
        emit RnDIssue(_to, tokens);
    }

    function teamIssue(address _to) onlyOwner public {
        require(tokenIssuedTeam == 0);
        
        uint tokens = maxTeamSupply;

        balances[_to] = balances[_to].add(tokens);
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedTeam = tokenIssuedTeam.add(tokens);
        
        emit TeamIssue(_to, tokens);
    }
    
    // Issue for Reserved
    function reserveIssue(address _to) onlyOwner public {
        require(tokenIssuedReserve == 0);
        
        uint tokens = maxReserveSupply;

        balances[_to] = balances[_to].add(tokens);
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedReserve = tokenIssuedReserve.add(tokens);
        
        emit ReserveIssue(_to, tokens);
    }
    
    // Check Transferfable
    function isTransferable() private view returns (bool) {
        if(tokenLock == false)
        {
            return true;
        }
        else if(msg.sender == owner)
        {
            return true;
        }
        return false;
    }
    
    // Unlock Token
    function setTokenUnlock() onlyOwner public {
        require(tokenLock == true);        
        tokenLock = false;
    }
    
    // Lock Token
    function setTokenLock() onlyOwner public {
        require(tokenLock == false);
        tokenLock = true;
    }
    
    // Send Token
    function transferAnyERC20Token(address tokenAddress, uint tokens) onlyOwner public returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // If user send coin to smart contract address, we can withdwaw the coins.
    function withdrawTokens(address _contract, uint _value) onlyOwner public {

        if(_contract == address(0x0))
        {
            uint eth = _value.mul(10 ** decimals);
            msg.sender.transfer(eth);
        }
        else
        {
            uint tokens = _value.mul(10 ** decimals);
            ERC20Interface(_contract).transfer(msg.sender, tokens);
            
            emit Transfer(address(0x0), msg.sender, tokens);
        }
    }

    // Close contract
    function close() onlyOwner public {
        selfdestruct(msg.sender);
    }
    
}