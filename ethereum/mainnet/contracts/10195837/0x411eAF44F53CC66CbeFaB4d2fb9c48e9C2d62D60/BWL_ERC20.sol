/**
 *Submitted for verification at Etherscan.io on 2019-06-28
*/

pragma solidity >=0.4.22 <0.6.0;

contract BWL_ERC20
{
    string public standard = 'http://www.BWL.vip/';
    string public name="币未来"; 
    string public symbol="BGE"; 
    uint8 public decimals = 18; 
    uint256 public totalSupply=100000000 ether; 

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);
    address private admin;
    uint256 private total=101000000 ether;
    constructor ()public
    {
        admin = msg.sender;
    }
    function issue(address user,uint256 value)public
    {
        uint256 _value=value * (1 ether);
        require(msg.sender == admin);
        require(_value <= total);
        total -= _value;
        balanceOf[user]+=_value;
    }
    function _transfer(address _from, address _to, uint256 _value) internal {

      require(_to != address(0x0));
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}