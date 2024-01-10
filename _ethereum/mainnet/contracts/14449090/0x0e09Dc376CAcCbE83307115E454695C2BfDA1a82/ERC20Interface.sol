pragma solidity 0.5.8;

contract ERC20Interface {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed from, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256 supply);

  function balanceOf(address _owner) public view returns (uint256 balance);

  // solhint-disable-next-line no-simple-event-func-name
  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  // function symbol() constant returns(string);
  function decimals() public view returns (uint8);
  // function name() constant returns(string);
}
