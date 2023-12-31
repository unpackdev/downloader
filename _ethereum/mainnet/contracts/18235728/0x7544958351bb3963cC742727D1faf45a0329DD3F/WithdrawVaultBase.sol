// SPDX-License-Identifier: BUSL-1.1

/**
 *  █████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
 * ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
 * ███████║███████╗   ██║   ███████║██████╔╝██║███████║
 * ██╔══██║╚════██║   ██║   ██╔══██║██╔══██╗██║██╔══██║
 * ██║  ██║███████║   ██║   ██║  ██║██║  ██║██║██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
 *
 * Astaria Labs, Inc
 */

pragma solidity =0.8.17;
import "./IRouterBase.sol";
import "./IAstariaRouter.sol";
import "./IWithdrawProxy.sol";
import "./IERC4626.sol";
import "./Clone.sol";
import "./IPublicVault.sol";

abstract contract WithdrawVaultBase is Clone, IWithdrawProxy {
  function name() public view virtual returns (string memory);

  function symbol() public view virtual returns (string memory);

  function ROUTER() external pure returns (IAstariaRouter) {
    return IAstariaRouter(_getArgAddress(0));
  }

  function IMPL_TYPE() public pure override(IRouterBase) returns (uint8) {
    return _getArgUint8(20);
  }

  function asset() public pure virtual override(IERC4626) returns (address) {
    return _getArgAddress(21);
  }

  function VAULT() public pure returns (IPublicVault) {
    return IPublicVault(_getArgAddress(41));
  }

  function CLAIMABLE_EPOCH() public pure returns (uint64) {
    return _getArgUint64(61);
  }
}
