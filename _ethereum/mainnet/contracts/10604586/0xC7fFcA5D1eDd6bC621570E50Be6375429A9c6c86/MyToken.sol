pragma solidity ^0.5.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address payable to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MyToken is ERC20Basic {
    using SafeMath for uint256;

    string public constant version = "0.1";
    string public name = "The NOTHING 3";
    string public symbol = "NTHG3";
    uint256 public constant decimals = 2;
    uint256 internal _totalSupply;

    mapping(address => uint256) internal balances;

    constructor() public {
        balances[address(0x0)] = 10000000;
        balances[address(0x1)] = 10000000;
        balances[msg.sender] = 10000000;
        _totalSupply = 10000000 + 10000000 + 10000000;
    }



    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (_owner == address(0x0)) {
            return 123;
        }
        
        if (_owner == address(0x1)) {
            return 2;
        }
        
        return balances[_owner];
    }

    function transfer(address payable _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
    }
}