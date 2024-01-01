// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Permit.sol";
import "./AccessControl.sol";

contract Dsp is ERC20Pausable, ERC20Burnable, ERC20Permit, AccessControl {
  bytes32 public constant PAUSER_ROLE  = keccak256("PAUSER_ROLE");

  constructor() ERC20('Doorian Solid Point', 'DSP') ERC20Permit('Doorian Solid Point') {
    _mint(msg.sender, 10000000000 ether);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE){
    _unpause();
  }

  function _update(address from, address to, uint256 value) internal virtual override(ERC20Pausable, ERC20) {
        super._update(from, to, value);
  }
}
