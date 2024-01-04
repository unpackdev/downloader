pragma solidity ^0.6.2;

import "./ERC20Burnable.sol";

contract BNLMToken is ERC20Burnable {
  /**
   * @dev Mints `initialSupply` amount of token and transfers them to `owner`.  
   *
   * See {ERC20-constructor}.
   */
  constructor(
      address owner
  ) public ERC20("Bancor Liquidity Mining T-Shirt Token", "BNLM") {
    _setupDecimals(8);
    uint256 initialSupply = 30000000000;
    _mint(owner, initialSupply);
  }
}