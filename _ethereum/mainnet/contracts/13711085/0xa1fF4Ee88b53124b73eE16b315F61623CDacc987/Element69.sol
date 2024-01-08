// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ERC20.sol";

contract Element69 is ERC20 {
  uint256 MAX_SUPPLY = 500_000_000;

  constructor() ERC20("Element 69", "EL69") {
    _mint(_msgSender(), MAX_SUPPLY * 10**18);
  }

  function transferMany(address[] memory addresses, uint256[] memory amounts)
    public
    returns (bool)
  {
    require(
      addresses.length == amounts.length,
      "EL69: Amount array must equal addresses length"
    );
    uint256 i;
    for (i = 0; i < addresses.length; i++) {
      _transfer(_msgSender(), addresses[i], amounts[i]);
    }
    return true;
  }
}
