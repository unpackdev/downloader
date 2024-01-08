// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./HabitatWallet.sol";
import "./VERCHelper.sol";

/// @notice Functionality for virtual ERC-20 (VERC-20).
contract HabitatVERC20 is HabitatWallet, VERCHelper {
  event VirtualERC20Created(address indexed account, address indexed token);

  /// @dev User invokable state transition.
  function onCreateVirtualERC20 (
    address msgSender,
    uint256 nonce,
    address factoryAddress,
    bytes calldata args
  ) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // only a weak protections for 'wrong' arguments.
    // The verification is offloaded to 'clients'.
    require(args.length >= 288, 'OCVE1');

    uint256 totalSupply;
    assembly {
      totalSupply := calldataload(add(args.offset, 96))
    }

    address tokenAddr = VERCHelper._getAddressForVERC(factoryAddress, args);
    require(_getTokenType(tokenAddr) == 0, 'OCVE2');

    _setTokenType(tokenAddr, 1);

    emit VirtualERC20Created(msgSender, tokenAddr);
    _transferToken(tokenAddr, address(0), msgSender, totalSupply);
  }
}
