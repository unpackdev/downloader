pragma solidity >=0.4.21 <0.7.0;

library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin- solidity/pull/522
        if (a == 0) {
            return 0; 
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
    * @dev Integer division of two numbers, truncating the quotient. 
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b; 
    }
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
           assert(b <= a);
           return a - b; 
    }
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
           c = a + b;
           assert(c >= a);
           return c; 
    }
}
contract Token {

    /// @return total amount of tokens
    //function totalSupply() public view returns (uint supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public  returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value)  public  returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public  returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public  view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RegularToken is Token {
    
    using SafeMath for uint256;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;

    function transfer(address _to, uint _value)  public   returns (bool) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        require(balances[msg.sender] >= _value);
        balances[msg.sender] =  balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)  public  returns (bool) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner)  public  view returns (uint) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public  returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public  view returns (uint) {
        return allowed[_owner][_spender];
    }

//    function totalSupply() public view returns (uint supply) {
//        return totalSupply;
//    }
}

contract UnboundedRegularToken is RegularToken {

    uint constant MAX_UINT = 2**256 - 1;
    
    /// @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited amount.
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        
        require(balances[_from] >= _value);
        require(allowance >= _value);
        
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract PUToken is UnboundedRegularToken {
    
    uint8 public decimals = 6;
    string public name = "PUToken";
    string public symbol = "PU";

    uint public singleCirculation = 0;
    uint public nextCirculationTime;
    uint public cutCycle = 1;
    uint public nextCutTime;
    uint public maxSupply = 5500 * 10 ** 10;
    uint public ownerMaxSupply = 55 * 10 ** 10;
    uint public ownerSupply = 0;
    uint public single = 1375 * 10 ** 8;
    uint public ownerNextCirculationTime;
    bool public mine;
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier mineStart {
        require(mine==true);
        _;
    }

    constructor() public {
        totalSupply = 385 * 10 ** 10;
        owner = msg.sender;
        singleCirculation = 4 * 10 ** 10;
        uint nowTime = now;
        nextCirculationTime = nowTime + 9999 days;
        ownerNextCirculationTime = nowTime + 90 days;
        nextCutTime = nowTime + 365 days;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender, totalSupply);
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function startMine() onlyOwner public {
        mine = true;
        uint nowTime = now;
        nextCirculationTime = nowTime + 1 days;
    }

    function ownerCirculation() public {
        uint nowTime = now;
        require(nowTime >= ownerNextCirculationTime);
        require(totalSupply.add(single) <= maxSupply);
        require(ownerSupply.add(single) <= ownerMaxSupply);

        ownerSupply = ownerSupply.add(single);
        balances[owner] = balances[owner].add(single);
        ownerNextCirculationTime = ownerNextCirculationTime + 90 days;
        emit Transfer(address(0),owner, single);
    }

    function addCirculation() mineStart public {
        uint nowTime = now;
        require(nowTime >= nextCirculationTime);
        require(totalSupply.add(singleCirculation) <= maxSupply);

        totalSupply = totalSupply.add(singleCirculation);
        balances[owner] = balances[owner].add(singleCirculation);
        nextCirculationTime = nextCirculationTime + 1 days;
        emit Transfer(address(0),owner, singleCirculation);
        //25%
        if(nowTime >= nextCutTime){
            cutCycle = cutCycle + 1;
            nextCutTime = nextCutTime + 365 days;
            if(cutCycle == 7){
                singleCirculation = (maxSupply.sub(totalSupply)).div(365);
            }else if(cutCycle < 7){
                singleCirculation = singleCirculation.mul(75).div(100);
            }
        }
    }
}