pragma solidity ^0.5.0;

contract MayKinFunds {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event treePlanted(address indexed contributor, uint256 amount);
    uint256 constant private MAX_UINT = 2**256 - 1;
    mapping(address=>uint256) public balances;
    mapping(address=>mapping(address=>uint256))public allowed;
    mapping(address=>uint256) public BofC;
    mapping(address=>uint256)public treeContribution;
    mapping(address=>uint256) public treesPlanted;
    string public constant name = "MayKinFund";
    string public constant symbol = "love";
    uint8 public constant decimals = 18;
    uint256 public constant tillNextTree = 1e18 * 100;
    uint256 public constant totalSupply = 5000000000000000000000000;
    address private constant owner = 0x7219E5c8767861CEa48Fe53feCCD2770f5310BF2;
    address adr = address(this);
    
    address payable wall = address(uint160(adr));
    function add(uint256 a, uint256 b) internal pure
    returns(uint256){
        uint256 c = a + b;
        assert(c>=a);
        return c;
    }
    
    function plantCheck(address _from, uint256 _amount)internal view returns(uint256){
        
        uint256 conT = treeContribution[_from] + _amount;
        if(conT<=tillNextTree){
            return 1;
        } else {
            return conT / tillNextTree;

        }
    }
    function sub(uint256 a, uint256 b)internal
    pure returns(uint256){
        assert(b<=a);
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal
    pure returns(uint256){
        uint256 c = a * b;
        assert(b == c / a);
        return c;
    }
    function balanceOf(address _owner)public view
    returns(uint256){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value)public
    returns(bool success){
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = sub(balances[msg.sender], _value);
        
        balances[_to] = add(balances[_to], _value);
        treeContribution[msg.sender]=add(treeContribution[msg.sender], _value);
        uint256 up = plantCheck(msg.sender, _value);
        if(up > treesPlanted[msg.sender]){
            treesPlanted[msg.sender]= up;
            emit treePlanted(msg.sender,up);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value)public
    returns(bool success){
        
        require(balances[_from]>=_value
        && allowed[_from][msg.sender]>=_value);
        balances[_from] = sub(balances[_from], _value);
        balances[_to] = add(balances[_to], _value);
        treeContribution[_from] = add(treeContribution[_from], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value)public
    returns(bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner,address _spender)public view
    returns(uint256){
        return allowed[_owner][_spender];
    }
    constructor() public{
        balances[wall] = totalSupply/2;
        balances[owner] = totalSupply/2;
    }
    function withdrawl(uint256 _value)public returns(bool success){
        require(msg.sender == owner);
        require(BofC[wall]>=_value);
        BofC[wall] = sub(BofC[wall],_value);
        
        owner.call.value(_value)("");
        return true;
    }
    function() external payable{
        BofC[wall] = add(BofC[wall],msg.value);
        uint256 buyAmount = mul(msg.value,100);
        if(balances[wall]>=buyAmount 
        && buyAmount >0){
            balances[msg.sender] = add(balances[msg.sender],buyAmount);
            treeContribution[msg.sender] = add(treeContribution[msg.sender],buyAmount);
            uint256 up = plantCheck(msg.sender, treeContribution[msg.sender]);
            if(up>treesPlanted[msg.sender]){
                treesPlanted[msg.sender]=up;
                emit treePlanted(msg.sender, up);
            }
            balances[wall] = sub(balances[wall], buyAmount);
            emit Transfer(wall, msg.sender, buyAmount);
        } else {
            treeContribution[msg.sender]=add(treeContribution[msg.sender],buyAmount);

            }
        }
    
    
}