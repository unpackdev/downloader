/**

 *Submitted for verification at Etherscan.io on 2020-09-05

*/

 

pragma solidity ^0.4.24;

 

 

 

 

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}

 

 

contract Owned {

   

    address public owner;

 

    event OwnershipTransferred(address indexed _from, address indexed _to);

 

    constructor() public {

        owner = 0xd5C3bBfDBE58aae010fdce79547874A4B8272Df3;

    }

 

    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }

 

    // transfer Ownership to other address

    function transferOwnership(address _newOwner) public onlyOwner {

        require(_newOwner != address(0x0));

        emit OwnershipTransferred(owner,_newOwner);

        owner = _newOwner;

    }

   

}

 

contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

 

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

 

contract DAGNIO  is ERC20Interface, Owned {

   

    using SafeMath for uint;

   

    string fwa4t;string fau5w1t;string faw69tut;string fwa3rt;string faw22t;string f2qat;string f3hat;string fa3vt;

    string fwawt;string fau3wt;string fa8wtut;string fw5art;string f3awyt;string fqa4et;string f2h889at;string fav999t;

    string fat;

    string fwat;string fauwt;string fawtut;string fwart;string fawt;string fqat;string fhat;string favt;

    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;

    uint public RATE;

    uint public DENOMINATOR;

    bool public isStopped = false;

    string fw5at;string fau2wt;string fawt0ut;string fwa7rt;string f6awt;string fq2a6t;string fh6at;string fa5vt6;

 

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;

   

    event Mint(address indexed to, uint256 amount);

    event ChangeRate(uint256 amount);

   

    modifier onlyWhenRunning {

        require(!isStopped);

        _;

    }

 

   

    constructor() public {

        name = "Acheloios.Finance";

        symbol = "ACH";

        decimals = 18;

        _totalSupply = 333000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;

         RATE = 1000;

        DENOMINATOR = 10000;

        emit Transfer(address(0), owner, _totalSupply);

    }

   

   

   

    function() public payable {

       

        buyTokens();

    }

   

   

   

    function buyTokens() onlyWhenRunning public payable {

        require(msg.value > 0);

       

        uint tokens = msg.value.mul(RATE).div(DENOMINATOR);

        require(balances[owner] >= tokens);

       

        balances[msg.sender] = balances[msg.sender].add(tokens);

        balances[owner] = balances[owner].sub(tokens);

       

        emit Transfer(owner, msg.sender, tokens);

       

        owner.transfer(msg.value);

    }

   

   

   

    function totalSupply() public view returns (uint) {

        return _totalSupply;

    }

 

 

  

    function balanceOf(address tokenOwner) public view returns (uint balance) {

        return balances[tokenOwner];

    }

 

 

  

    function transfer(address to, uint tokens) public returns (bool success) {

        require(to != address(0));

        require(tokens > 0);

        require(balances[msg.sender] >= tokens);

       

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;

    }

 

 

   

    function approve(address spender, uint tokens) public returns (bool success) {

        require(spender != address(0));

        require(tokens > 0);

       

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;

    }

 

 

   

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

        require(from != address(0));

        require(to != address(0));

        require(tokens > 0);

        require(balances[from] >= tokens);

        require(allowed[from][msg.sender] >= tokens);

       

        balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(from, to, tokens);

        return true;

    }

 

 

  

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }

   

   

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {

        require(_spender != address(0));

       

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

   

   

   

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {

        require(_spender != address(0));

       

        uint oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {

            allowed[msg.sender][_spender] = 0;

        } else {

            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

   

  

    function changeRate(uint256 _rate) public onlyOwner {

        require(_rate > 0);

       

        RATE =_rate;

        emit ChangeRate(_rate);

    }

   

}