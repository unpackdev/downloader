pragma solidity ^0.6.2;

import "./ERC20Burnable.sol";

contract BNVTToken is ERC20Burnable {
  /**
   * @dev Mints `initialSupply` amount of token and transfers them to `owner`.  
   *
   * See {ERC20-constructor}.
   */
  constructor(
      address owner
  ) public ERC20("Bancor V2.1 T-Shirt Token", "BNVT") {
    _setupDecimals(8);
    uint256 initialSupply = 20000000000;
    _mint(owner, initialSupply);
  }
}