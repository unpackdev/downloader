pragma solidity >=0.5.0 <0.7.0;

import "./console.sol";
import "./ERC20.sol";

contract MUSDMock is ERC20 {
  constructor(address to, uint256 amount) public ERC20('mStable USD', 'mUSD') {
    _mint(to, amount);
  }

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}
