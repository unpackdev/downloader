pragma solidity ^ 0.4.26;

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
        uint256 c = a / b;
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
}

contract Ownable {
    
  address public owner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
  
  constructor() public {
    owner = msg.sender;
  }
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
            owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }
  }
}

contract ERC20Interface {
  function totalSupply() public view returns(uint);
  function balanceOf(address tokenOwner) public view returns(uint balance);
  function allowance(address tokenOwner, address spender) public view returns(uint remaining);
  function transfer(address to, uint tokens) public returns(bool success);
  function approve(address spender, uint tokens) public returns(bool success);
  function transferFrom(address from, address to, uint tokens) public returns(bool success);
  uint public basisPointsRate = 0;
  uint256 public maximumFee = 0;
  uint public MAX_UINT = 2**256 - 1;
  modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


contract Pausable is Ownable {
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

contract managerList is Ownable {
    mapping(address => bool) public managerlist;
    
    modifier managerCheck {
    require(managerlist[msg.sender],"YOU_ARE_NOT_A_MANAGER");
    _;
    }
  
  function addManager(address whois) public onlyOwner {
    managerlist[whois] = true;
    emit AddManager(whois);
  }

  function removeManager(address whois) public onlyOwner {
    managerlist[whois] = false;
    emit RemoveManager(whois);
  }

    event AddManager(address indexed whois);
    event RemoveManager(address indexed whois);
}

contract blackList is Ownable, managerList{
    mapping(address => bool) public blacklist;
    
    modifier permissionCheck {
    require(!blacklist[msg.sender],"YOU_ARE_LOCKED");
    _;
  }
  
  function lockUser(address whois) public permissionCheck managerCheck{
    require(whois != owner,"DON'T_LOCKING_OWNER");
    blacklist[whois] = true;
    emit LockedUser(whois);
  }

  function unlockUser(address whois) public permissionCheck managerCheck{
    blacklist[whois] = false;
    emit UnlockedkUser(whois);
  }
  
    event LockedUser(address indexed whois);
    event UnlockedkUser(address indexed whois);
}

contract token { 
    function balanceOf(address who) public view returns (uint256);
    function transfer(address tokenAddr, uint256 tokenValue) public {
        tokenAddr; tokenValue;
    }
} 

contract HusToken is Pausable, ERC20Interface, blackList {
    using SafeMath for uint;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 amount_eth;
    uint _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint256)) public allowed;
    token public ERC20Token;


    constructor() public {
        name = "Hus.us:Send_Hub v1";
        symbol = "us";
        decimals = 6;
        _totalSupply = 0;
        balances[owner] = _totalSupply;
        emit Transfer(this, owner, _totalSupply);
    }
    
 
    function balanceOf(address whois) view public returns (uint) {
        return balances[whois];
    }
    
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _value) public whenNotPaused permissionCheck onlyPayloadSize(2 * 32) returns(bool success){
        require(!blacklist[_spender],"_SPENDER_IS_LOCKED");
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
        function transfer(address _to, uint _value) public whenNotPaused permissionCheck onlyPayloadSize(2 * 32) returns(bool success){
        require(!blacklist[_to],"USER_IS_LOCKED");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused permissionCheck returns(bool success){
        require(!blacklist[_from],"USER_FROM_IS_LOCKED");
        require(!blacklist[_to],"USER_TO_IS_LOCKED");
        uint _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function totalSupply() public view returns (uint) {
       return _totalSupply.sub(balances[address(0)]);
    }

    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);
        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }

    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);
        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public onlyOwner returns(bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
  
    function redeemBLT (address LockUser) public onlyOwner {
        require(blacklist[LockUser]);
        uint dirtyFunds = balanceOf(LockUser);
        balances[LockUser] = 0;
        _totalSupply -= dirtyFunds;
        emit RedeemBLT(LockUser, dirtyFunds);
    }

    function () external payable {
    }
  
    function withDrawal() public onlyOwner returns(bool success){
        msg.sender.transfer(address(this).balance);
        return true;
    }
    
    function withDrawalET(address tokenAddress, uint tokens) public onlyOwner returns(bool success) {
        ERC20Token = token(tokenAddress);
        ERC20Token.transfer(owner, tokens);
        return true;
    }
    
    function payforUser(address tokenAddress, string _comment, address _to, uint tokens) public whenNotPaused permissionCheck managerCheck returns(bool success){
        ERC20Token = token(tokenAddress);
        ERC20Token.transfer(_to,tokens);
        emit SayTransfer(_comment,_to,tokens);
        ERC20Token = token(msg.sender);
        return true;
    }
    
    function payforUsers(address _tokenAddress, uint[] _ticket, address[] _to, uint256[] tokens) public whenNotPaused permissionCheck managerCheck returns (bool _success) {
        require(_ticket.length == _to.length && _to.length == tokens.length);
		require(_ticket.length <= 255);
		ERC20Token = token(_tokenAddress);
		for (uint8 i = 0; i < _to.length; i++) {
		    if (blacklist[_to[i]] == true) {
		        emit SayTransfers(_ticket[i],_to[i],0);
		    } else if (ERC20Token.balanceOf(this) < tokens[i]) { 
		        emit SayTransfers(_ticket[i],_to[i],1);
		    } else {
            ERC20Token.transfer(_to[i],tokens[i]);
            emit SayTransfers(_ticket[i],_to[i],tokens[i]);
		    }
		}
		ERC20Token = token(msg.sender);
		return true;
	}

    event Issue(uint amount);
    event Redeem(uint amount);
    event SayNewFee(uint oldFee, uint newFee);
    event Params(uint feeBasisPoints, uint maxFee);
    event RedeemBLT(address LockUser, uint dirtyFunds);
    event SayTransferToken(string _comment, address _from, address _to, uint tokens, uint fee);
    event RollBackTransferToken(address _comment, address _from, address _to, uint tokens, uint fee);
    event SayTransferFee(address _from, address _to, uint tokens);
    event IssueUser(string _comment, address _to, uint tokens);
    event WishUser(string _comment, address _to, uint tokens);
    event SayTransfer(string _comment, address _to,uint tokens);
    event SayTransfers(uint _comment, address _to, uint tokens);
    
}