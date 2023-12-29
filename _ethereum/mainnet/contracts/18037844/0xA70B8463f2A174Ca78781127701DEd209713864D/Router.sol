// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract Router is Initializable, OwnableUpgradeable, UUPSUpgradeable {

  address private _primaryStakeholder;

  event Route(address indexed receiver, uint256 amount);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address primaryStakeholder_) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    _primaryStakeholder = primaryStakeholder_;
  }

  function route() external payable {
    _routePrimaryStakeholder(msg.value);
  }

  function _routePrimaryStakeholder(uint256 amount) private {
    (bool sent,) = _primaryStakeholder.call{value: amount}("");
    require(sent, "Failed to send Ether");

    emit Route(_primaryStakeholder, amount);
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
  {}

  receive() external payable {}
}