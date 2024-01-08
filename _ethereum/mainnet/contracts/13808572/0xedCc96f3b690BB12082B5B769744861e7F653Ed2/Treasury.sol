//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";

import "./BumperAccessControl.sol";

contract Treasury is Initializable, BumperAccessControl {
  using SafeERC20 for IERC20;
  
  function initialize(address[] calldata _whitelist) 
    public 
    initializer 
  {
    _BumperAccessControl_init(_whitelist);
  }

  /// @notice Transfer tokens from the contract to the address.
  function withdraw(
      address to,
      address token,
      uint256 amount
  ) 
    external 
    onlyGovernanceOrOwner 
  {
      IERC20(token).safeTransfer(to, amount);
  }

  /// @notice Transfer ETH from the contract to the address.
  function withdrawETH(
      address payable to,
      uint256 amount
  ) 
    external 
    payable
    onlyGovernanceOrOwner 
  {
      to.transfer(amount);
  }

  /// @notice Execute transactions
  /// @param to Destination address of transaction.
  /// @param value Ether value of transaction.
  /// @param data Data payload of transaction.
  function execute(
      address to,
      uint256 value,
      bytes calldata data
  ) 
    external
    payable
    onlyGovernanceOrOwner
    returns (bytes memory)
  {
    require(AddressUpgradeable.isContract(to), "call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = to.call{value: value}(data);
    return AddressUpgradeable.verifyCallResult(success, returndata, "call failed");
  }

  /// @notice Receive Ether
  receive() external payable { }

}
