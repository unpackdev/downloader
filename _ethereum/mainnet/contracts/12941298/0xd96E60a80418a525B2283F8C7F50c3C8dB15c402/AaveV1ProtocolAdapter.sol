// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./AaveV1Interfaces.sol";
import "./AaveV1Erc20Adapter.sol";
import "./AaveV1EtherAdapter.sol";
import "./AbstractProtocolAdapter.sol";


contract AaveV1ProtocolAdapter is AbstractProtocolAdapter {
  using CloneLibrary for address;

/* ========== Constants ========== */

  ILendingPoolAddressesProvider public constant aave = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
  ILendingPoolCore public immutable core;
  address public constant ETH_RESERVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public immutable erc20AdapterImplementation;
  address public immutable etherAdapterImplementation;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) AbstractProtocolAdapter(_registry) {
    core = aave.getLendingPoolCore();
    erc20AdapterImplementation = address(new AaveV1Erc20Adapter(aave));
    etherAdapterImplementation = address(new AaveV1EtherAdapter(aave));
  }

/* ========== Internal Actions ========== */

  function deployAdapter(address underlying) internal virtual override returns (address adapter) {
    if (underlying == ETH_RESERVE_ADDRESS) {
      adapter = etherAdapterImplementation.createClone();
      AaveV1EtherAdapter(payable(adapter)).initialize(weth, core.getReserveATokenAddress(underlying));
    } else {
      adapter = erc20AdapterImplementation.createClone();
      AaveV1Erc20Adapter(adapter).initialize(underlying, core.getReserveATokenAddress(underlying));
    }
  }

/* ========== Public Queries ========== */

  function protocol() external pure virtual override returns (string memory) {
    return "Aave V1";
  }

  function getUnmapped() public view virtual override returns (address[] memory tokens) {
    tokens = core.getReserves();
    uint256 len = tokens.length;
    uint256 prevLen = totalMapped;
    if (len == prevLen) {
      assembly { mstore(tokens, 0) }
    } else {
      assembly {
        tokens := add(tokens, mul(prevLen, 32))
        mstore(tokens, sub(len, prevLen))
      }
    }
  }

/* ========== Internal Queries ========== */

  function isAdapterMarketFrozen(address adapter) internal view virtual override returns (bool) {
    return isTokenMarketFrozen(IErc20Adapter(adapter).underlying());
  }

  function isTokenMarketFrozen(address underlying) internal view virtual override returns (bool) {
    return core.getReserveIsFreezed(underlying);
  }
}

