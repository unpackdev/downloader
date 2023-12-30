pragma solidity ^0.4.8;

/**
 * Math operations with safety checks
 */
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }
}

contract ChangeInterface {
    function change(address _from, address _to, uint256 _value) public returns (bool success);
}


contract USDT is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    ChangeInterface USDD;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public changeOf;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AllowChange(address from, uint256 value);
    event CancelChange(address from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function USDT(uint _initialSupply) {
        balanceOf[msg.sender] = _initialSupply;
        // Give the creator all initial tokens
        totalSupply = _initialSupply;
        // Update total supply
        name = "USDT";
        // Set the name for display purposes
        symbol = 'USDT';
        // Set the symbol for display purposes
        decimals = 8;
        // Amount of decimals for display purposes
        owner = msg.sender;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;
        // Prevent transfer to 0x0 address.
        if (_value <= 0) throw;
        if (balanceOf[msg.sender] < _value) throw;
        // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        // Add the same to the recipient
        Transfer(msg.sender, _to, _value);
        // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
    returns (bool success) {
        if (_value <= 0) throw;
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;
        // Prevent transfer to 0x0 address.
        if (_value <= 0) throw;
        if (balanceOf[_from] < _value) throw;
        // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;
        // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }


    function setUSDD(address value) public returns (bool success){
        require(msg.sender == owner);
        USDD = ChangeInterface(value);
        return true;
    }


    function allowChange(uint256 _value) returns (bool success){
        if (_value <= 0) throw;
        if (balanceOf[msg.sender] - changeOf[msg.sender] < _value) throw;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        changeOf[msg.sender] = SafeMath.safeAdd(changeOf[msg.sender], _value);
        AllowChange(msg.sender, _value);
        return true;
    }

    function cancelChange(uint256 _value) returns (bool success){
        if (_value <= 0) throw;
        if (changeOf[msg.sender] < _value) throw;
        changeOf[msg.sender] = SafeMath.safeSub(changeOf[msg.sender], _value);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        CancelChange(msg.sender, _value);
        return true;
    }

    function change(address _from, address _to, uint256 _value) public returns (bool success){
        require(msg.sender == address(USDD));
        if (_to == 0x0) throw;
        if (_value <= 0) throw;
        if (changeOf[_from] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;

        changeOf[_from] = SafeMath.safeSub(changeOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        return true;
    }

    function changeUSDD(address _to, uint256 _value){
        transfer(_to, _value);

        USDD.change(_to, msg.sender, _value);
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint amount) public {
        require(msg.sender == owner);
        require(totalSupply + amount > totalSupply);
        require(balanceOf[owner] + amount > balanceOf[owner]);

        balanceOf[owner] += amount;
        totalSupply += amount;
    }

    // Called when new token are issued
    event Issue(uint amount);

}