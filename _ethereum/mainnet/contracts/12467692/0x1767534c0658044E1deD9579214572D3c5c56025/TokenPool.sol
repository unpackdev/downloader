pragma solidity 0.5.17;

import "./IERC20.sol";

import "./Ownable.sol";


/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract needs to hold multiple distinct pools of the same token.
 */
contract TokenPool is Ownable
{
  IERC20 public token;


  constructor(IERC20 _token) public
  {
    token = _token;
  }

  function balance() public view returns (uint)
  {
    return token.balanceOf(address(this));
  }

  function transfer(address _to, uint _value) external onlyOwner returns (bool)
  {
    return token.transfer(_to, _value);
  }
}
