// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract PuulAccessControl is AccessControl {
  using SafeERC20 for IERC20;

  bytes32 constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  bytes32 constant ROLE_MEMBER = keccak256("ROLE_MEMBER");
  bytes32 constant ROLE_MINTER = keccak256("ROLE_MINTER");
  bytes32 constant ROLE_EXTRACT = keccak256("ROLE_EXTRACT");
  bytes32 constant ROLE_HARVESTER = keccak256("ROLE_HARVESTER");
  
  constructor () public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyAdmin() {
    require(hasRole(ROLE_ADMIN, msg.sender), "!admin");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(ROLE_MINTER, msg.sender), "!minter");
    _;
  }

  modifier onlyExtract() {
    require(hasRole(ROLE_EXTRACT, msg.sender), "!extract");
    _;
  }

  modifier onlyHarvester() {
    require(hasRole(ROLE_HARVESTER, msg.sender), "!harvester");
    _;
  }

  modifier onlyDefaultAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "!default_admin");
    _;
  }

  function _setup(bytes32 role, address user) internal {
    if (msg.sender != user) {
      _setupRole(role, user);
      revokeRole(role, msg.sender);
    }
  }

  function _setupDefaultAdmin(address admin) internal {
    _setup(DEFAULT_ADMIN_ROLE, admin);
  }

  function _setupAdmin(address admin) internal {
    _setup(ROLE_ADMIN, admin);
  }

  function setupDefaultAdmin(address admin) external onlyDefaultAdmin {
    _setupDefaultAdmin(admin);
  }

  function setupAdmin(address admin) external onlyAdmin {
    _setupAdmin(admin);
  }

  function setupMinter(address admin) external onlyMinter {
    _setup(ROLE_MINTER, admin);
  }

  function setupExtract(address admin) external onlyExtract {
    _setup(ROLE_EXTRACT, admin);
  }

  function setupHarvester(address admin) external onlyHarvester {
    _setup(ROLE_HARVESTER, admin);
  }

  function _tokenInUse(address /*token*/) virtual internal view returns(bool) {
    return false;
  }

  function extractStuckTokens(address token, address to) onlyExtract external {
    require(token != address(0) && to != address(0));
    // require(!_tokenInUse(token)); // TODO add back after beta
    uint256 balance = IERC20(token).balanceOf(address(this));
    if (balance > 0)
      IERC20(token).safeTransfer(to, balance);
  }

}