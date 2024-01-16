// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

contract BabyProofofMemes {

    constructor () {
        balances[msg.sender] = 1000000*10**18;
        totalSupply = 1000000*10**18;
        name = "Baby Proof of Memes";
        decimals = 18;
        symbol = "BPOM";
        FeePercent = 49;
        FeePercent2 = 49;

        Burn1 = 0xf9C2AdE5c127563bE6Ab91bb57fAA0a251fFD947;
        Dev2 = 0xf9C2AdE5c127563bE6Ab91bb57fAA0a251fFD947;

        admin = msg.sender;
        ImmuneFromFee[address(this)] = true;
        ImmuneFromFee[msg.sender] = true;
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
    uint public FeePercent2;
    mapping(address => bool) public ImmuneFromFee;
    address public admin;
    address Burn1;
    address Dev2;

    function EditFee(uint Fee) public {
        require(msg.sender == admin, "You aren't the admin so you can't press this button!");
        require(Fee <= 100, "You cannot make the fee higher than 100%");
        FeePercent = Fee;
    }

    function EditFee2(uint Fee) public {
        require(msg.sender == admin, "You aren't the admin so you can't press this button!");
        require(Fee <= 100, "You cannot make the fee higher than 100%");
        FeePercent2 = Fee;
    }

    function ExcludeFromFee(address Who) public {
        require(msg.sender == admin, "You aren't the admin so you can't press this button!");

        ImmuneFromFee[Who] = true;
    }

    function IncludeFromFee(address Who) public {
        require(msg.sender == admin, "You aren't the admin so you can't press this button!");

        ImmuneFromFee[Who] = false;
    }

    function ProcessFee(uint _value, address _payee) internal returns (uint){
        uint fee = FeePercent*(_value/100);
        _value -= fee;

        balances[_payee] -= fee;
        balances[Burn1] += fee;
        emit Transfer(_payee, Burn1, fee);
        return _value;
    }

    function ProcessFee2(uint _value, address _payee) internal returns (uint){
        uint fee = FeePercent2*(_value/100);
        _value -= fee;

        balances[_payee] -= fee;
        balances[Dev2] += fee;
        emit Transfer(_payee, Dev2, fee);
        return _value;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "You can't send more tokens than you have");

        _value = ProcessFee(_value, msg.sender);
        _value = ProcessFee2(_value, msg.sender);

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        _value = ProcessFee(_value, _from);
        _value = ProcessFee2(_value, _from);

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