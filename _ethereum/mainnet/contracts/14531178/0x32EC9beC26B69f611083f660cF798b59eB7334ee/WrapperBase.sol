// SPDX-License-Identifier: MIT
pragma solidity  >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./IDex.sol";

abstract contract WrapperBase is Ownable, ReentrancyGuard, IDex {
  ///@notice Address of the dex manager
  address public dexManager;

  ///@notice Enforces sender to be dex manager
  bool public enforceDexManager;

  constructor(address _dexManager) {
    dexManager = _dexManager;
    enforceDexManager = true;
  }

  //-----------------
  //----------------- Owner methods -----------------
  //-----------------
  /// @notice Enforces caller to be the Dex Manager only
  function allowOnlyManager() external onlyOwner {
    enforceDexManager = true;
    emit AllowManager(msg.sender);
  }

  /// @notice Allows everyone to be the msg sender
  function allowEveryone() external onlyOwner {
    enforceDexManager = false;
    emit AllowEveryone(msg.sender);
  }

  /// @notice Sets the dex manager address
  /// @param _dexManager Dex manager address
  function setManager(address _dexManager) external onlyOwner {
    require(_dexManager != address(0), "ERR: INVALID ADDRESS");
    emit ManagerChanged(msg.sender, dexManager, _dexManager);
    dexManager = _dexManager;
  }

  modifier enforceDexManagerAddress() {
    if (enforceDexManager) {
      require(msg.sender == dexManager, "ERR: UNAUTHORIZED");
    }
    _;
  }

  modifier onlyValidAddress(address _address) {
      require(_address != address(0), "ERR: INVALID ADDRESS");
      _;
  }

  modifier noValue(){
    require(msg.value == 0, "ERR: NO VALUE");
    _;
  }
}