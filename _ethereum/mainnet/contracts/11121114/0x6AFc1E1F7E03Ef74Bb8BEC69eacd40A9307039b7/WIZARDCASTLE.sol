/**
 *
 * OFFICIAL WIZARD TRILOGY
 * 
 * Security audited
*/

pragma solidity ^0.5.16;

contract WIZARDCASTLE {
    string public name; // Public name
    string public symbol; // Public Symbol
    uint8 public decimals = 18; // Decimals 
    uint256 public totalSupply; // Total supply
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Initial constructor
     */
    constructor() public {
        totalSupply = 50 * 10 ** uint256(18);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "WIZARD CASTLE";                                   // Set the name for display purposes
        symbol = "CSTL";                               // Set the symbol for display purposes
    }

    /**
     * Internal function
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value); // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for buffer overflows
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value;  // Add the same to the recipient
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}