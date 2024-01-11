// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./IMakerDAOParameters.sol";
import "./IDssVest.sol";

contract MakerDAOParameters is IMakerDAOParameters {
  address public constant override DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant override DAI_JOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
  address public constant override DSS_VEST = 0x2Cc583c0AaCDaC9e23CB601fDA8F1A0c56Cdcb71;
  address public constant override MAKER_DAO = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
  address public constant override VOW = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;

  uint256 public override minBuffer = 4_000 ether;
  uint256 public override maxBuffer = 20_000 ether;
  uint256 public override vestId; // TBD

  constructor() {
    emit BufferSet(minBuffer, maxBuffer);
  }

  // Views

  /// @inheritdoc IMakerDAOParameters
  function buffer() external view override returns (uint256 _minBuffer, uint256 _maxBuffer) {
    return (minBuffer, maxBuffer);
  }

  // Setters

  /// @inheritdoc IMakerDAOParameters
  function setBuffer(uint256 _minBuffer, uint256 _maxBuffer) external onlyMaker {
    minBuffer = _minBuffer;
    maxBuffer = _maxBuffer;

    emit BufferSet(_minBuffer, _maxBuffer);
  }

  /// @inheritdoc IMakerDAOParameters
  function setVestId(uint256 _vestId) public onlyMaker {
    (address _usr, uint48 _bgn, uint48 _clf, uint48 _fin, , , uint128 _tot, ) = IDssVest(DSS_VEST).awards(_vestId);
    if (_usr != address(this)) revert IncorrectVestId();
    vestId = _vestId;

    emit VestSet(_vestId, _bgn, _clf, _fin, _tot);
  }

  // Modifiers

  modifier onlyMaker() {
    if (msg.sender != MAKER_DAO) revert OnlyMaker();
    _;
  }
}
