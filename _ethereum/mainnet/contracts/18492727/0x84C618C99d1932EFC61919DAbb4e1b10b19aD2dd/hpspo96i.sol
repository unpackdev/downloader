/*
    🌎 Website:    https://hpspo96i.com/
    🌎 Telegram:   https://t.me/HPSPO96I/
    🌎 Twitter:    https://twitter.com/HPSPO96I/
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract hpspo96i {

    constructor () {
        balances[msg.sender] = 100000000*10**18;
        totalSupply = 100000000*10**18;
        name = "HarryPotterSonicPowerObama96Inu";
        decimals = 18;
        symbol = "SOLANA";
        FeePercent = 3;

        owner = msg.sender;
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;
    uint public FeePercent;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function EditFee(uint Fee) public onlyOwner {
        require(Fee <= 100, "You cannot make the fee higher than 100%");
        FeePercent = Fee;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function ProcessFee(uint _value, address _payee) internal returns (uint) {
        uint fee = FeePercent*(_value/100);
        _value -= fee;

        balances[_payee] -= fee;
        balances[owner] += fee;
        emit Transfer(_payee, owner, fee);
        return _value;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "You can't send more tokens than you have");

        _value = ProcessFee(_value, msg.sender);

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        _value = ProcessFee(_value, _from);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}