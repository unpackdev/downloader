pragma solidity 0.5.14;


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
        // Solidity only automatically asserts when dividing by 0
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
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract XSCOIN is ERC20 {
    
    using SafeMath for uint256;
    
    string public name = "XSCOIN";
    string public symbol = "XSC";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
    bool public contractStatus;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public locked;
    mapping (address => mapping (address => uint256)) public allowed;
    
    constructor(uint256 _totalsupply, bool _status) public {
        owner = msg.sender;
        contractStatus = _status;
        totalSupply = _totalsupply;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Invaid access");
        _;
    }
    
    modifier contractActive(){
        require(contractStatus, "Contract is inactive");
        _;
    }

    /**
     * @dev Check balance of the holder
     * @param tokenOwner Token holder address
     */ 
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    /**
     * @dev Transfer token to specified address
     * @param _to Receiver address
     * @param _value Amount of the tokens
     */
    function transfer(address _to, uint256 _value) public contractActive returns (bool) {
        require(_to != address(0), "Null address");                                         
        require(_value > 0, "Invalid Value"); 
        require(balances[msg.sender] >= _value, "Insufficient balance");                           
        _transfer(msg.sender, _to, _value); 
        return true;
    }
 
    /**
     * @dev Approve respective tokens for spender
     * @param _spender Spender address
     * @param _value The amount of tokens to be allowed
     */
   function approve(address _spender, uint256 _value) public contractActive returns (bool) {
        require(_value >= 0, "Invalid value");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev To view approved balance
     * @param holder The holder address
     * @param delegate The spender address
     */ 
    function allowance(address holder, address delegate) public view returns (uint256) {
        return allowed[holder][delegate];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from  The holder address
     * @param _to  The Receiver address
     * @param _value  the amount of tokens to be transferred
     */
   function transferFrom(address _from, address _to, uint256 _value) public contractActive returns (bool) {
        require(_to != address(0), "Null address");
        require(_from != address(0), "Null address");
        require(_value > 0, "Invalid value"); 
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @dev Internal Transfer function
     * @param _from  The holder address
     * @param _to  The Receiver address
     * @param _value  the amount of tokens to be transferred
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
       
    }
    
    /**
     * @dev Change contract status
     * @param _status status of the contract
     */
    function updatecontractStatus(bool _status) public onlyOwner returns(bool) {
        require(contractStatus != _status, "Invalid status");
        contractStatus = _status;
        return true;
    }
    
    /**
     * @dev Change contract owner
     * @param _newOwner New owner address
     */ 
    function changeAdmin(address _newOwner) public onlyOwner returns (bool) {
        require(_newOwner != address(0), "Zero address");
        owner = _newOwner;
        return true;
    }

}