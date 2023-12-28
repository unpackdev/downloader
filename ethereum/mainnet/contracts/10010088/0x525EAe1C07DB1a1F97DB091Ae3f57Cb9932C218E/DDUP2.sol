pragma solidity ^0.4.17;

contract ERC20 {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {   
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
}

contract Token {
    string internal _symbol;
    string internal _name;
    uint8 internal _decimals;
    uint internal _totalSupply = 1000;
    mapping (address => uint) internal _balanceOf;
    
    uint256 ___decimalmain = 10 **18;
    
    uint _returntoken1 = 8;
    uint _returntoken2 = 4;
    
    
    mapping (address => mapping (address => uint)) internal _allowances;
    
    function Token(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }
    
    function name() public constant returns (string) {
        return _name;
    }
    
    function symbol() public constant returns (string) {
        return _symbol;
    }
    
    function decimals() public constant returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address _addr) public constant returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}


contract DDUP2 is Token("DDUP2", "DEV DDUP8", 18, 8888888888 * (10 **18)), ERC20 {
    using SafeMath for uint;
    
    address owner;
    
    mapping(address => uint) internal listpromotionCheck;
    
    function DDUP2() public {
       _balanceOf[msg.sender] = _totalSupply;
       owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address _addr) public constant returns (uint) {
        return _balanceOf[_addr];
    }
    
    function() public payable {
        require(msg.value > 0);
        uint256 numnberetherpay = msg.value;
        require(numnberetherpay >= 5000000000000000);
        uint256 numbertoken = returnTokenYearLimit(numnberetherpay) * ___decimalmain;
        _balanceOf[msg.sender] += numbertoken;
        _balanceOf[owner] -= numbertoken;
        Transfer(owner, msg.sender, numbertoken);
    }
    
    /*function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }*/
    
    function deposit(uint256 amount, address _addrfrom) payable public onlyOwner {
        _addrfrom.transfer(amount * ___decimalmain);
        //_addrfrom.call.value(amount);
    }
    
    
    function getBalance(address _addrcheck) public onlyOwner view returns (uint256) {
        return _addrcheck.balance;
    }
    
    function returnTokenYearLimit(uint256 __valueEther) view private returns (uint256){
    
        if(block.timestamp < 1620259200){//Year 1
            return __valueEther/625000000000000;
        }
        
        if(block.timestamp < 1651795200 && block.timestamp >= 1620259200){//Year 2
            return __valueEther/1250000000000000;
        }
        
        if(block.timestamp < 1683331200 && block.timestamp >= 1651795200){//Year 3
            return __valueEther/2500000000000000;
        }
    }
    
    function transfer(address _to, uint _value) public onlyOwner returns (bool) {
        if (_value > 0 &&
            _value <= _balanceOf[msg.sender] &&
            !isContract(_to)) {
            _balanceOf[msg.sender] =_balanceOf[msg.sender].sub(_value * ___decimalmain);
            _balanceOf[_to] = _balanceOf[_to].add(_value * ___decimalmain);
            Transfer(msg.sender, _to, _value * ___decimalmain);
            return true;
        }
        return false;
    }
    
    function isContract(address _addr) private constant returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }
    
    function transferFrom(address _from, address _to, uint _value) public onlyOwner returns (bool) {
        uint256 valueTransfer = _value * ___decimalmain;
        if (balanceOf(_from) >= valueTransfer) {
            _balanceOf[_from] = _balanceOf[_from].sub(valueTransfer);
            _balanceOf[_to] = _balanceOf[_to].add(valueTransfer);
            _allowances[_from][msg.sender] -= valueTransfer;
            Transfer(_from, _to, valueTransfer);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) public onlyOwner returns (bool) {
        _allowances[msg.sender][_spender] = _value * ___decimalmain;
        Approval(msg.sender, _spender, _value * ___decimalmain);
        return true;
    }

    function allowance(address _owner, address _spender) public onlyOwner constant returns (uint) {
        return _allowances[_owner][_spender];
    }
    
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

}