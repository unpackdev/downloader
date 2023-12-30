pragma solidity ^0.5.1;

contract transferable { function transfer(address to, uint256 value) public returns (bool); }
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; }

contract Vibexxx {
    string public name = "Vibexxx";
    string public symbol = "VBX";
    uint8 public decimals = 18;
    address public owner;
    uint256 public _totalSupply = 100000000000000000000000000000;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
        balances[address(0x7d5517F7529aB42C38F93B6C31620b59c51cA442)] = (_totalSupply * 70) / 100;
        balances[address(0x1dc3b5e6a7D7C3e8E0eE263570F5a4cBa3f1Df92)] = (_totalSupply * 10) / 100;
        balances[address(0x1654b47b771843a358eD8a7afcaaE6e36D66250a)] = (_totalSupply * 10) / 100;
        balances[address(0xc4EBCAF54ff1E205f4461A7f6817fB36190053bf)] = (_totalSupply * 3) / 100;
        balances[address(0x124182eBa81D886598Fa1018efecF46A69237137)] = (_totalSupply * 3) / 100;
        balances[address(0xDbA08e1D2B37479D58482d77356aAd7aF779c18c)] = (_totalSupply * 2) / 100;
        balances[address(0x4B1bBb61A5c03142e779E029Fc802BD8c9801642)] = (_totalSupply * 2) / 100;
        owner = msg.sender;
        emit Transfer(address(0x0), address(0x7d5517F7529aB42C38F93B6C31620b59c51cA442), (_totalSupply * 70) / 100);
        emit Transfer(address(0x0), address(0x1dc3b5e6a7D7C3e8E0eE263570F5a4cBa3f1Df92), (_totalSupply * 10) / 100);
        emit Transfer(address(0x0), address(0x1654b47b771843a358eD8a7afcaaE6e36D66250a), (_totalSupply * 10) / 100);
        emit Transfer(address(0x0), address(0xc4EBCAF54ff1E205f4461A7f6817fB36190053bf), (_totalSupply * 3) / 100);
        emit Transfer(address(0x0), address(0x124182eBa81D886598Fa1018efecF46A69237137), (_totalSupply * 3) / 100);
        emit Transfer(address(0x0), address(0xDbA08e1D2B37479D58482d77356aAd7aF779c18c), (_totalSupply * 2) / 100);
        emit Transfer(address(0x0), address(0x4B1bBb61A5c03142e779E029Fc802BD8c9801642), (_totalSupply * 2) / 100);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0x0)) return false;
        if (balances[msg.sender] < _value) return false;
        if (balances[_to] + _value < balances[_to]) return false;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }        

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0x0)) return false;
        if (balances[_from] < _value) return false;
        if (balances[_to] + _value < balances[_to]) return false;
        if (_value > allowances[_from][msg.sender]) return false;
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value) return false;
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        if (balances[_from] < _value) return false;
        if (_value > allowances[_from][msg.sender]) return false;
        balances[_from] -= _value;
        _totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return transferable(tokenAddress).transfer(owner, tokens);
    }
}