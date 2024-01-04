// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IKeep3rV1.sol";
import "./IKeep3r.sol";

abstract
contract Keep3r is IKeep3r {

  IKeep3rV1 internal _Keep3r;
  address public bond;
  uint256 public minBond;
  uint256 public earned;
  uint256 public age;
  bool public onlyEOA;

  constructor(address _keep3r) public {
    _setKeep3r(_keep3r);
  }

  // Setters
  function _setKeep3r(address _keep3r) internal {
    _Keep3r = IKeep3rV1(_keep3r);
    emit Keep3rSet(_keep3r);
  }

  function _setKeep3rRequirements(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA) internal {
    bond = _bond;
    minBond = _minBond;
    earned = _earned;
    age = _age;
    onlyEOA = _onlyEOA;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age, _onlyEOA);
  }

  // Modifiers
  // Only checks if caller is a valid keeper, payment should be handled manually
  modifier onlyKeeper() {
    _isKeeper();
    _;
  }

  // view
  function keep3r() external view override returns (address _keep3r) {
    return address(_Keep3r);
  }

  // Checks if caller is a valid keeper, handles default payment after execution
  modifier paysKeeper() {
    _;
    _Keep3r.worked(msg.sender);
  }
  // Checks if caller is a valid keeper, handles payment amount after execution
  modifier paysKeeperAmount(uint256 _amount) {
    _;
    _Keep3r.workReceipt(msg.sender, _amount);
  }
  // Checks if caller is a valid keeper, handles payment amount in _credit after execution
  modifier paysKeeperCredit(address _credit, uint256 _amount) {
    _;
    _Keep3r.receipt(_credit, msg.sender, _amount);
  }
  // Checks if caller is a valid keeper, handles payment amount in ETH after execution
  modifier paysKeeperEth(uint256 _amount) {
    _;
    _Keep3r.receiptETH(msg.sender, _amount);
  }

  // Internal helpers
  function _isKeeper() internal {
    if (onlyEOA) require(msg.sender == tx.origin, "keep3r::isKeeper:keeper-is-not-eoa");
    if (minBond == 0 && earned == 0 && age == 0) {
      // If no custom keeper requirements are set, just evaluate if sender is a registered keeper
      require(_Keep3r.isKeeper(msg.sender), "keep3r::isKeeper:keeper-is-not-registered");
    } else {
      if (bond == address(0)) {
        // Checks for min KP3R, earned and age.
        require(_Keep3r.isMinKeeper(msg.sender, minBond, earned, age), "keep3r::isKeeper:keeper-not-min-requirements");
      } else {
        // Checks for min custom-bond, earned and age.
        require(_Keep3r.isBondedKeeper(msg.sender, bond, minBond, earned, age), "keep3r::isKeeper:keeper-not-custom-min-requirements");
      }
    }
  }
}
