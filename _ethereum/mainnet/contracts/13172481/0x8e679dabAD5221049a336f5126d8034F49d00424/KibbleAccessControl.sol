// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessControl.sol";
import "./Ownable.sol";

abstract contract KibbleAccessControl is AccessControl, Ownable {
  /// @notice role based events
  event BurnerAdded(address burner);
  event MinterAdded(address minter);

  /// @notice set minter role, ie staking contracts
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

  /// @notice set minter role, ie staking contracts
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  /// @notice onlyBurner modifier
  modifier onlyBurner() {
    require(
      hasRole(BURNER_ROLE, msg.sender),
      'KibbleAccessControl: Only burner'
    );
    _;
  }

  /// @notice setup a burner role can only be set by dev
  /// @param _burner burner address
  function setupBurner(address _burner) external onlyOwner {
    require(
      _isContract(_burner),
      'KibbleAccessControl: Burner can only be a contract'
    );
    _setupRole(BURNER_ROLE, _burner);

    emit BurnerAdded(_burner);
  }

  /// @notice onlyMinter modifier
  modifier onlyMinter() {
    require(
      hasRole(MINTER_ROLE, msg.sender),
      'KibbleAccessControl: Only minter'
    );
    _;
  }

  /// @notice setup minter role can only be set by dev
  /// @param _minter minter address
  function setupMinter(address _minter) external onlyOwner {
    require(
      _isContract(_minter),
      'KibbleAccessControl: Minter can only be a contract'
    );
    _setupRole(MINTER_ROLE, _minter);

    emit MinterAdded(_minter);
  }

  /// @notice Check if an address is a contract
  function _isContract(address _addr) internal view returns (bool isContract_) {
    uint256 size;
    assembly {
      size := extcodesize(_addr)
    }
    isContract_ = size > 0;
  }
}
