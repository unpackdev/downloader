/**
*
*
         dP                   dP                         dP                   
         88                   88                         88                   
.d8888b. 88 .d8888b. .d8888b. 88d888b. dP   .dP .d8888b. 88 dP    dP .d8888b. 
Y8ooooo. 88 88'  `88 Y8ooooo. 88'  `88 88   d8' 88'  `88 88 88    88 88ooood8 
      88 88 88.  .88       88 88    88 88 .88'  88.  .88 88 88.  .88 88.  ... 
`88888P' dP `88888P8 `88888P' dP    dP 8888P'   `88888P8 dP `88888P' `88888P' 
                                                                              
*
* 
* SlashValue
* https://SlashValue.Com
* 
**/

pragma solidity 0.5.16; 

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: Addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: Subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when divide by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: Modulo by zero");
        return a % b;
    }
}


contract ERC20 {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns(bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract SVToken is ERC20 {
    
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public burnAddress;
    uint256 public burnMul;
    address public owner;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => bool) public authorized;

    constructor (address _burnAddress) public {
        symbol = "SVT";
        name = "Slash Value Token";
        decimals = 18;
        burnAddress = _burnAddress;
        owner = msg.sender;
        burnMul = 0.05 ether;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
 
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balances[msg.sender], "Insufficient balance");
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        uint256 burnFee = (_value.mul(burnMul)).div(10**20);
        uint256 balanceFee = _value.sub(burnFee);
        balances[burnAddress] = balances[burnAddress].add(burnFee);
        balances[_to] = balances[_to].add(balanceFee);
        
        emit Transfer(msg.sender, _to, balanceFee);
        emit Transfer(msg.sender, burnAddress, burnFee);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0), "Invalid from address");
        require(_to != address(0), "Invalid to address");
        require(_value <= balances[_from], "Invalid balance");
        require(_value <= allowed[_from][msg.sender], "Invalid allowance");
        
        balances[_from] = balances[_from].sub(_value);
        uint256 burnFee = (_value.mul(burnMul));
        uint256 balanceFee = _value.sub(burnFee);
        balances[burnAddress] = balances[burnAddress].add(burnFee);
        balances[msg.sender] = balances[msg.sender].add(balanceFee);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, balanceFee);
        emit Transfer(_from, burnAddress, burnFee);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Null address");
        require(_value > 0, "Invalid value");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }  
    
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "Invalid Address");
        owner = _newOwner;
        return true;
    }
   
    function changeBurnt(address _burnAddress, uint8 _burnMul) public onlyOwner returns(bool) {
        require(_burnAddress != address(0), "Invalid Address");
        burnAddress = _burnAddress;
        burnMul = _burnMul;
        return true;
    }
    
    function changeAuthorized(address _addr, bool _status) public onlyOwner returns(bool) {
        require(_addr != address(0), "Invalid Address");
        authorized[_addr] = _status;
        return true;
    }
    
    function authorizedMint(address _receiver, uint256 _amount) public returns (bool) {
        require(authorized[msg.sender], "Authorized only");
        require(_receiver != address(0), "Invalid address");
        require(_amount >= 0, "Invalid amount");
        totalSupply = totalSupply.add(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        emit Transfer(address(0), _receiver, _amount);
        return true;
    }
    
    function mint(address _receiver, uint256 _amount) public onlyOwner returns (bool) {
        require(_receiver != address(0), "Invalid address");
        require(_amount >= 0, "Invalid amount");
        totalSupply = totalSupply.add(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        emit Transfer(address(0), _receiver, _amount);
        return true;
    }
}