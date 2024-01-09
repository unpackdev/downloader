// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./ECDSA.sol";
import "./IDCAKeep3rJob.sol";
import "./Governable.sol";

contract DCAKeep3rJob is Governable, IDCAKeep3rJob {
  using ECDSA for bytes32;

  IKeep3rJobs public immutable keep3r;
  uint256 public nonce;
  address public swapper;
  mapping(address => bool) public canAddressSignWork;

  constructor(
    address _swapper,
    IKeep3rJobs _keep3r,
    address _governor
  ) Governable(_governor) {
    if (address(_keep3r) == address(0)) revert ZeroAddress();
    if (address(_swapper) != address(0)) swapper = _swapper;
    keep3r = _keep3r;
  }

  function setSwapper(address _swapper) external onlyGovernor {
    if (address(_swapper) == address(0)) revert ZeroAddress();
    swapper = _swapper;
    emit NewSwapperSet(_swapper);
  }

  function setIfAddressCanSign(address _address, bool _canSign) external onlyGovernor {
    if (_address == address(0)) revert ZeroAddress();
    canAddressSignWork[_address] = _canSign;
    emit ModifiedAddressPermission(_address, _canSign);
  }

  function work(bytes calldata _bytes, bytes calldata _signature) external {
    if (!keep3r.isKeeper(msg.sender)) revert NotAKeeper();

    address _signer = keccak256(_bytes).toEthSignedMessageHash().recover(_signature);
    if (!canAddressSignWork[_signer]) revert SignerCannotSignWork();

    WorkCall memory _call = abi.decode(_bytes, (WorkCall));
    if (_call.nonce != nonce++) revert InvalidNonce();
    if (_call.deadline < block.timestamp) revert DeadlineExpired();
    if (_call.chainId != block.chainid) revert InvalidChainId();

    _callSwapper(_call.swapperCall);

    keep3r.worked(msg.sender);
  }

  function _callSwapper(bytes memory _call) internal virtual {
    // solhint-disable-next-line avoid-low-level-calls
    (bool _success, ) = swapper.call(_call);
    if (!_success) revert SwapperCallFailed();
  }
}
