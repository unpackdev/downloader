pragma solidity ^0.4.24;

/*
 
\     /  ////////// /////////  /\      /
 \   /   /          /       /  / \     /
  \ /    /          /       /  /  \    /
   \     /////////  /       /  /   \   /
  / \    /          /       /  /    \  /
 /   \   /          /       /  /     \ /
/     \  /////////  /////////  /      \/


*/

// ----------------------------------------------------------------------------
// Xeon token contract
//
// website       : xeonfinserv.wordpress.com 
// Symbol        : XEON
// Name          : XEON FINSERV
// Total supply  : 1
// Decimals      : 18
// ----------------------------------------------------------------------------


contract SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
    assert(c / a == b);
    return c;
    }
    
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
	    uint256 c = safeAdd(a,m);
	    uint256 d = safeSub(c,1);
	    return mul(safeDiv(d,m),m);
	  }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event BurnXeon(address indexed from, uint256 value);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract XEONToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint256 public xeonbasepercent = 100;

    constructor() public {
        symbol = "XEON";
        name = "XEON FINSWAP";
        decimals = 18;
        _totalSupply = 1000000000000000000;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(to != address(0));

        uint256 tokensToBurn = xeon(tokens);
        uint256 tokensToTransfer = safeSub(tokens,tokensToBurn);
    
        balances[msg.sender] = safeSub(balances[msg.sender],tokens);
        balances[to] = safeAdd(balances[to],tokensToTransfer);
    
        _totalSupply = safeSub(_totalSupply, tokensToBurn);
    
        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, address(0), tokensToBurn);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function xeon(uint256 value) public view returns (uint256)  {
	    uint256 roundValue = ceil(value, xeonbasepercent);
	    uint256 _xeonPercent = safeDiv(mul(roundValue, xeonbasepercent), 20000);
	    return _xeonPercent;
	  }

    function () public payable {
        revert();
    }
}