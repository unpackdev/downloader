pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";


interface IHead {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract gHead is ERC20, IHead, Ownable {

  mapping(address => bool) controllers;       
  IERC20 public erc20Token;

  
  constructor() ERC20("gHEAD", "GHEAD") { }

  function mint(address to, uint256 amount) external override {                    
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return super.balanceOf(account);
  }

  function transfer(address recipient, uint256 amount) public virtual override  returns (bool) {
    return super.transfer(recipient, amount);

  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return super.allowance(owner, spender);
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    return super.approve(spender, amount);
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
    return super.decreaseAllowance(spender, subtractedValue);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20, IHead) returns (bool) {
    if(controllers[_msgSender()]) {
      _transfer(sender, recipient, amount);
      return true;
    }

    return super.transferFrom(sender, recipient, amount);
  }




}