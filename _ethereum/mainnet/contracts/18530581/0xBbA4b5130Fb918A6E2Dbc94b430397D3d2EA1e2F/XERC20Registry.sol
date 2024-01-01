// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "./SafeERC20.sol";
import "./IERC20.sol";
import "./AccessControlUpgradeable.sol";
import "./IXERC20.sol";
import "./IXERC20Lockbox.sol";
import "./IXERC20Registry.sol";
import "./console.sol";

contract XERC20Registry is IXERC20Registry, AccessControlUpgradeable {
  /**
   * @notice Maps ERC20 to XERC20, if registered
   */
  mapping(address => address) public ERC20ToXERC20;

  /**
   * @notice Maps XERC20 to ERC20, if registered
   */
  mapping(address => address) public XERC20ToERC20;

  /**
   * @notice Stores all registered XERC20s
   */
  address[] public XERC20s;

  /**
   * @notice Role allowed to register/deregister XERC20s
   * @dev Role: 0xd6b769dbdbf190871759edfb79bd17eda0005e1b8c3b6b3f5b480b5604ad5014
   */
  bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR");

  /**
   * @notice Initializer function
   */
  function initialize() public initializer {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /**
   * @notice Adds an xERC20 to the registry
   * @param _ERC20 The address of the ERC20
   * @param _XERC20 The address of the xERC20
   */
  function registerXERC20(address _XERC20, address _ERC20) external onlyRole(REGISTRAR_ROLE) {
    if (XERC20ToERC20[_XERC20] != address(0)) {
      revert AlreadyRegistered(_XERC20);
    }
    if (_XERC20 == address(0)) revert InvalidXERC20Address(_XERC20);
    if (_ERC20 == address(0) && !_isNativeLockbox(_XERC20)) {
      revert NotNativeLockbox(_XERC20);
    }

    ERC20ToXERC20[_ERC20] = _XERC20;
    XERC20ToERC20[_XERC20] = _ERC20;
    XERC20s.push(_XERC20);

    emit XERC20Registered(_XERC20, _ERC20);
  }

  /**
   * @notice Removes an xERC20 from the registry
   * @param _XERC20 The address of the xERC20
   */
  function deregisterXERC20(address _XERC20) external onlyRole(REGISTRAR_ROLE) {
    address ERC20 = XERC20ToERC20[_XERC20];
    if (ERC20 == address(0) && !_isNativeLockbox(_XERC20)) {
      revert NotRegistered(_XERC20);
    }
    if (ERC20 == address(0)) revert NotRegistered(_XERC20);

    delete ERC20ToXERC20[ERC20];
    delete XERC20ToERC20[_XERC20];

    uint256 idx = XERC20s.length;
    for (uint256 i = 0; i < XERC20s.length; i++) {
      if (XERC20s[i] == _XERC20) {
        idx = i;
        break;
      }
    }

    if (idx < XERC20s.length - 1) {
      XERC20s[idx] = XERC20s[XERC20s.length - 1];
    }
    XERC20s.pop();

    emit XERC20Deregistered(_XERC20, ERC20);
  }

  /**
   * @notice Returns the corresponding canonical ERC20 for a given xERC20
   * @dev Reverts if the xERC20 is not registered
   * @param _XERC20 The address of the xERC20
   */
  function getERC20(address _XERC20) public view returns (address) {
    address ERC20 = XERC20ToERC20[_XERC20];
    if (ERC20 == address(0) && !_isNativeLockbox(_XERC20)) {
      revert NotRegistered(_XERC20);
    }
    return ERC20;
  }

  /**
   * @notice Returns the corresponding XERC20 for a given ERC20
   * @dev Reverts if the ERC20 is not registered
   * @param _ERC20 The address of the ERC20
   */
  function getXERC20(address _ERC20) public view returns (address) {
    address XERC20 = ERC20ToXERC20[_ERC20];
    if (XERC20 == address(0)) revert NotRegistered(_ERC20);
    return XERC20;
  }

  /**
   * @notice Returns the Lockbox for a given asset
   * @dev Reverts if the given token is not registered
   * @param _token The address of either the ERC20 or XERC20 to look up
   */
  function getLockbox(address _token) external view returns (address) {
    if (isXERC20(_token)) {
      return IXERC20(_token).lockbox();
    } else {
      address XERC20 = getXERC20(_token);
      return IXERC20(XERC20).lockbox();
    }
  }

  /**
   * @notice Checks if a given asset is an xERC20
   * @param _XERC20 The address of the asset to look up
   */
  function isXERC20(address _XERC20) public view returns (bool) {
    address ERC20 = XERC20ToERC20[_XERC20];
    if (ERC20 == address(0)) return _isNativeLockbox(_XERC20);
    return true;
  }

  /**
   * @notice Utility function to check if a given xERC20 has a native Lockbox
   * @param _XERC20 The address of the asset to look up
   */
  function _isNativeLockbox(address _XERC20) private view returns (bool) {
    bytes memory data = abi.encodeWithSelector(IXERC20.lockbox.selector, msg.sender);
    (bool success,) = _XERC20.staticcall(data);
    if (success) {
      return IXERC20Lockbox(IXERC20(_XERC20).lockbox()).IS_NATIVE();
    }
    return false;
  }
}
