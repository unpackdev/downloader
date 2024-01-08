// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./ERC20PermitUpgradeable.sol";

import "./TokenControllerInterface.sol";
import "./ControlledTokenInterface.sol";

contract ControlledToken is ERC20PermitUpgradeable, ControlledTokenInterface {

  TokenControllerInterface public override controller;

  function initialize(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    TokenControllerInterface _controller
  )
    public
    virtual
    initializer
  {
    __ERC20_init(_name, _symbol);
    __ERC20Permit_init("ArchiPrize ControlledToken");
    controller = _controller;
    _setupDecimals(_decimals);
  }

  function controllerMint(address _user, uint256 _amount) external virtual override onlyController {
    _mint(_user, _amount);
  }

  function controllerBurn(address _user, uint256 _amount) external virtual override onlyController {
    _burn(_user, _amount);
  }

  function controllerBurnFrom(address _operator, address _user, uint256 _amount) external virtual override onlyController {
    if (_operator != _user) {
      uint256 decreasedAllowance = allowance(_user, _operator).sub(_amount, "CONTROLLEDTOKEN:EXCEEDS_ALLOWANCE");
      _approve(_user, _operator, decreasedAllowance);
    }
    _burn(_user, _amount);
  }

  modifier onlyController {
    require(_msgSender() == address(controller), "CONTROLLEDTOKEN:ONLY_CONTROLLER");
    _;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    controller.beforeTokenTransfer(from, to, amount);
  }
}
