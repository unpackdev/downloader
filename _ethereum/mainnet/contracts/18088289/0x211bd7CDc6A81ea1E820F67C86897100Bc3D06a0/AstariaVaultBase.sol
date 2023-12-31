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

import "./IAstariaVaultBase.sol";
import "./Clone.sol";
import "./IERC4626.sol";
import "./ICollateralToken.sol";
import "./IAstariaRouter.sol";
import "./IRouterBase.sol";

abstract contract AstariaVaultBase is Clone, IAstariaVaultBase {
  function name() external view virtual returns (string memory);

  function symbol() external view virtual returns (string memory);

  function ROUTER() public pure returns (IAstariaRouter) {
    return IAstariaRouter(_getArgAddress(0)); //ends at 20
  }

  function IMPL_TYPE() public pure returns (uint8) {
    return _getArgUint8(20); //ends at 21
  }

  function owner() public pure returns (address) {
    return _getArgAddress(21); //ends at 41
  }

  function asset()
    public
    pure
    virtual
    override(IAstariaVaultBase)
    returns (address)
  {
    return _getArgAddress(41); //ends at 41
  }

  function START() public pure returns (uint256) {
    return _getArgUint256(61); // ends at 93
  }

  function EPOCH_LENGTH() public pure returns (uint256) {
    return _getArgUint256(93); //ends at 125
  }

  function VAULT_FEE() public pure returns (uint256) {
    return _getArgUint256(125); //ends at 157
  }

  function COLLATERAL_TOKEN() public view returns (ICollateralToken) {
    return ROUTER().COLLATERAL_TOKEN();
  }
}
