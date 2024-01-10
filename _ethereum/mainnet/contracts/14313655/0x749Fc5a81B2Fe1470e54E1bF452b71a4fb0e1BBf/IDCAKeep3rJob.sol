// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./IKeep3rJobs.sol";
import "./IGovernable.sol";

interface IDCAKeep3rJob is IGovernable {
  /// @notice A call to execute work
  struct WorkCall {
    // The actual call to the swapper contract
    bytes swapperCall;
    uint256 nonce;
    uint256 chainId;
    uint256 deadline;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when a user tries to execute work but the signature is invalid
  error SignerCannotSignWork();

  /// @notice Thrown when a user tries to execute work with an invalid nonce
  error InvalidNonce();

  /// @notice Thrown when a user tries to execute work with an expired deadline
  error DeadlineExpired();

  /// @notice Thrown when a user tries to execute work with an invalid chain id
  error InvalidChainId();

  /// @notice Thrown when a user tries to execute work but the call to the swapper fails
  error SwapperCallFailed();

  /// @notice Thrown when a non keep3r address tries to execute work
  error NotAKeeper();

  /// @notice Emitted when a new swapper is set
  /// @param newSwapper The new swapper
  event NewSwapperSet(address newSwapper);

  /// @notice Emitted when a new keep3r is set
  /// @param newKeep3r The new keep3r
  event NewKeep3rSet(IKeep3rJobs newKeep3r);

  /// @notice Emitted when signing permission is modified for an address
  /// @param affected The affected address
  /// @param canSign Whether the affected address can now sign work or not
  event ModifiedAddressPermission(address affected, bool canSign);

  /// @notice Returns the swapper address
  /// @return The swapper's address
  function swapper() external returns (address);

  /// @notice Returns the Keep3r address
  /// @return The Keep3r address address
  function keep3r() external returns (IKeep3rJobs);

  /// @notice Returns whether the given address can sign work or not
  /// @return If it can sign work or not
  function canAddressSignWork(address _address) external returns (bool);

  /// @notice Returns the nonce to use when calling `work`
  /// @return The nonce to use
  function nonce() external returns (uint256);

  /// @notice Sets a new swapper address
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _swapper The new swapper address
  function setSwapper(address _swapper) external;

  /// @notice Sets whether the given address can sign work or not
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _address The address to modify permissions
  /// @param _canSign Whether the given address will be able to sign work or not
  function setIfAddressCanSign(address _address, bool _canSign) external;

  /// @notice Takes an encoded call to execute against the swapper contract, and executes it
  /// @dev Will revert with:
  /// NotAKeeper if the caller is not a keep3r
  /// SignerCannotSignWork if the address who signed the message cannot sign work
  /// InvalidNonce if the nonce is invalid
  /// DeadlineExpired if the deadline has expired
  /// InvalidChainId if the chain id is invalid
  /// SwapperCallFailed if the call to the swapper failed
  /// @param _bytes An encoded `WorkCall`
  /// @param _signature A signature of `_bytes`
  function work(bytes calldata _bytes, bytes calldata _signature) external;
}
