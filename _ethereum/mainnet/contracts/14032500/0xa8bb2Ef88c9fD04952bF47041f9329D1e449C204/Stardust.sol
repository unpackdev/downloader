// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";

contract Stardust is ERC20, ERC20Burnable, AccessControl {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  constructor() ERC20("Stardust", "$Stardust") {
    _mint(address(this), 7200000 ether);
    _mint(_msgSender(), 7200000 ether);
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function withdraw(address _address, uint256 _amount)
    external
    onlyRole(MANAGER_ROLE)
  {
    require(_amount <= balanceOf(address(this)), "Not enough $Stardust left");

    _transfer(address(this), _address, _amount);
  }
}
