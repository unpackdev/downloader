// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Clones.sol";
import "./FixedPeriod.sol";
import "./OwnableUpgradeable.sol";
import "./IFixedPeriodDeployer.sol";

contract FixedPeriodDeployer is IFixedPeriodDeployer, OwnableUpgradeable {
  address public immutable FIXEDPERIOD_IMPL;

  constructor() {
    __Ownable_init(msg.sender);
    FIXEDPERIOD_IMPL = address(new FixedPeriod());
  }

  function deployFixedPeriod(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _timelock,
    address _erc20,
    address payable _platform,
    address payable _receivingAddress,
    uint256 _initialRate,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _maxSupply,
    uint256 _platformRate
  ) public override onlyOwner returns (address) {
    address clone = Clones.clone(FIXEDPERIOD_IMPL);

    FixedPeriod(clone).initialize(
      _name,
      _symbol,
      _bURI,
      _timelock,
      _erc20,
      _platform,
      _receivingAddress,
      _initialRate,
      _startTime,
      _endTime,
      _maxSupply,
      _platformRate
    );
    return clone;
  }
}
