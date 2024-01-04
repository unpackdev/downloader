pragma solidity ^0.6.2;

import "./ERC20Burnable.sol";

contract BNTeeToken is ERC20Burnable {
  /**
   * @dev Mints `initialSupply` amount of token and transfers them to `owner`.  
   *
   * See {ERC20-constructor}.
   */
  constructor(
      address owner
  ) public ERC20("Bancor T-Shirt Token", "BNTEE") {
    _setupDecimals(8);
    uint256 initialSupply = 10000000000;
    _mint(owner, initialSupply);
  }
}