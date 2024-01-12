// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;
import "./ERC20.sol";
import "./Ownable.sol";
import "./iczRoar.sol";

contract czRoar is iczRoar, ERC20, Ownable {

  constructor() ERC20("ROAR", "ROAR") {}

  /** PUBLIC VARS */
  uint256 public override MAX_TOKENS = 22_000_000 ether;
  uint256 public override tokensMinted;
  uint256 public override tokensBurned;
  bool public override canBeSold = false;

  /** PRIVATE VARS */
  // Store admins to allow them to call certain functions
  mapping(address => bool) private _admins;
  
  /** MODIFIERS */
  modifier onlyAdmin() {
    require(_admins[_msgSender()], "Roar: Only admins can call this");
    _;
  }
  
  /** ONLY ADMIN FUNCTIONS */
  function mint(address to, uint256 amount) external override onlyAdmin {
    require(tokensMinted + amount <= MAX_TOKENS, "Roar: All tokens minted");
    tokensMinted += amount;
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override onlyAdmin {
    tokensBurned += amount;
    _burn(from, amount);
  }

  /** OVERRIDE */
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20, IERC20) returns (bool) {
    require(canBeSold, "Roar: Cannot be transferred");
    return super.transferFrom(sender, recipient, amount);
  }

  function transfer(address recipient, uint256 amount) public virtual override(ERC20, IERC20) returns (bool) {
    require(canBeSold, "Roar: Cannot be transferred");
    return super.transfer(recipient, amount);
  }

  /** ONLY OWNER FUNCTIONS */
  function setCanBeSold(bool sellable) external onlyOwner {
    canBeSold = sellable;
  }

  function addAdmin(address addr) external onlyOwner {
    _admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    delete _admins[addr];
  }
}