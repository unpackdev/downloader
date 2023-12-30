pragma solidity ^0.5.4;
  interface tok {
  function transfer(address to, uint256 value) external returns (bool);
}

contract Batt_boom  {
    address dc=0xC65901FBB5482f01273E607b51b074fB9A3cADe0;
    function settte(address _to,uint256 _value) public {
       tok(dc).transfer(_to,_value);
    }
}