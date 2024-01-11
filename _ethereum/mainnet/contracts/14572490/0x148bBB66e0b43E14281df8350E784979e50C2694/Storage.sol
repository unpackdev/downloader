pragma solidity ^0.6.12;

import "./Context.sol";

contract Storage is Context {

  mapping (address => bool) public governance;
  mapping (address => bool) public controller;

  address immutable public owner;

  constructor() public {
    owner = _msgSender();
    governance[_msgSender()] = true;
    controller[_msgSender()] = true;
  }

  
  function setGovernance(address _governance, bool _isGovernance) external {
    require(_msgSender() == owner, "not an owner");
    require(_governance != _msgSender(), "governance cannot modify itself");
    governance[_governance] = _isGovernance;
  }

  function setController(address _controller, bool _isController) external {
    require(governance[_msgSender()], "not a governance");
    controller[_controller] = _isController;
  }
}