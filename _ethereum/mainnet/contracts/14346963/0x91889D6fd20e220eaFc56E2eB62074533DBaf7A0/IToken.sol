pragma solidity ^0.8.0;

import "./IERC20.sol";
interface IToken is IERC20{
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
}
