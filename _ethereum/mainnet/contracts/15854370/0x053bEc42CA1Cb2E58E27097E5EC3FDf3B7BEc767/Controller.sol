// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IController.sol";
import "./IProxyControlled.sol";


contract Controller is IController {

  // *************************************************************
  //                        VARIABLES
  // *************************************************************

  address public override governance;
  address public pendingGovernance;
  mapping(address => bool) public operators;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event SetGovernance(address value);
  event ChangeOperatorStatus(address operator, bool status);

  // *************************************************************
  //                      CONSTRUCTOR
  // *************************************************************

  constructor () {
    governance = msg.sender;
    operators[msg.sender] = true;
  }

  // *************************************************************
  //                     RESTRICTIONS
  // *************************************************************

  modifier onlyGovernance() {
    require(msg.sender == governance, "!gov");
    _;
  }

  // *************************************************************
  //                        VIEWS
  // *************************************************************

  function isOperator(address _adr) external view override returns (bool) {
    return operators[_adr];
  }

  // *************************************************************
  //                     GOV ACTIONS
  // *************************************************************

  function updateProxies(address[] memory proxies, address[] memory newLogics) external onlyGovernance {
    require(proxies.length == newLogics.length, "Wrong arrays");
    for (uint i; i < proxies.length; i++) {
      IProxyControlled(proxies[i]).upgrade(newLogics[i]);
    }
  }

  function changeOperatorStatus(address operator, bool status) external onlyGovernance {
    operators[operator] = status;
    emit ChangeOperatorStatus(operator, status);
  }

  function setGovernance(address _value) external onlyGovernance {
    pendingGovernance = _value;
    emit SetGovernance(_value);
  }

  function acceptGovernance() external {
    require(msg.sender == pendingGovernance, "Not pending gov");
    governance = pendingGovernance;
  }

}
