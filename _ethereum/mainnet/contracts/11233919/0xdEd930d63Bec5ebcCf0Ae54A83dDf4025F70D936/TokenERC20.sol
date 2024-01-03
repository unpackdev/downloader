/**
 * Crazy No. 9 Coin
 * Note: The event ends within 24 hours, but the coins will continue to be traded and liquidity will not be cancelled!
*/

/**
 * 24-hour incentive activities
 * Purchasers within 24 hours have a chance to get 0.5 ETH rewards, there are 10 places in total
 * Holder first place: reward 10 ETH (need to hold a minimum of 99 CN9C)
 * Holder second place: reward 5 ETH (need to hold a minimum of 30 CN9C)
 * Third place holder: reward 2.5 ETH (need to hold a minimum of 15 CN9C)
*/

pragma solidity ^0.4.26;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
  string public name;
  string public symbol;
  uint8 public decimals = 18;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);
   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  event Burn(address indexed from, uint256 value);

  function TokenERC20(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol
  ) public {
    totalSupply = initialSupply * 10 ** uint256(decimals);
    balanceOf[msg.sender] = totalSupply;
    name = tokenName;  
    symbol = tokenSymbol;   
  }

  function _transfer(address _from, address _to, uint _value) internal {
    require(_to != 0x0);
    require(balanceOf[_from] >= _value);
    require(balanceOf[_to] + _value >= balanceOf[_to]);
    uint previousBalances = balanceOf[_from] + balanceOf[_to];
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= allowance[_from][msg.sender]); 
    allowance[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public
    returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  function burn(uint256 _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value); 
    balanceOf[msg.sender] -= _value; 
    totalSupply -= _value;   
    emit Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(balanceOf[_from] >= _value);  
    require(_value <= allowance[_from][msg.sender]);  
    balanceOf[_from] -= _value;   
    allowance[_from][msg.sender] -= _value; 
    totalSupply -= _value; 
    emit Burn(_from, _value);
    return true;
  }
}