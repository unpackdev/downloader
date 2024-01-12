// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./draft-ERC20PermitUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./Clones.sol";

interface TokenInterface{
  function destroyTokens(address _owner, uint _amount) external returns(bool);
  function generateTokens(address _owner, uint _amount) external returns(bool);
}
contract THTERC20 is Initializable, ERC20PermitUpgradeable, AccessControlUpgradeable, TokenInterface{

  bytes32 public constant MINTER = keccak256("MINTER");
  bytes32 public constant BURNER = keccak256("BURNER");

  function initialize(string memory name, string memory symbol) public initializer{

    __ERC20Permit_init(name);
    __ERC20_init(name, symbol);
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function generateTokens(address to, uint256 amount) public returns(bool){
    require(hasRole(MINTER, msg.sender), "only for minter");
    super._mint(to, amount);
    return true;
  }
  function destroyTokens(address from, uint256 amount) public returns(bool){
    require(hasRole(BURNER, msg.sender), "only for burner");
    super._burn(from, amount);
    return true;
  }

  function changeAdmin(address new_admin) public onlyRole(DEFAULT_ADMIN_ROLE){
    _grantRole(DEFAULT_ADMIN_ROLE, new_admin);
    _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

}
