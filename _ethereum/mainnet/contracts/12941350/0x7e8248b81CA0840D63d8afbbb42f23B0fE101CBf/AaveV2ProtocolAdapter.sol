// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./AaveV2Interfaces.sol";
import "./AaveV2Erc20Adapter.sol";
import "./AaveV2EtherAdapter.sol";
import "./ReserveConfigurationLib.sol";
import "./AbstractProtocolAdapter.sol";


contract AaveV2ProtocolAdapter is AbstractProtocolAdapter {
  using ReserveConfigurationLib for ILendingPool.ReserveConfigurationMap;

/* ========== Constants ========== */

  ILendingPoolAddressesProvider public constant aave = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
  ILendingPool public immutable pool;
  address public immutable erc20AdapterImplementation;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) AbstractProtocolAdapter(_registry) {
    erc20AdapterImplementation = address(new AaveV2Erc20Adapter(aave));
    pool = aave.getLendingPool();
  }

/* ========== Internal Actions ========== */

  function deployAdapter(address underlying) internal override returns (address adapter) {
    address aToken = pool.getReserveData(underlying).aTokenAddress;
    if (underlying == weth) {
      adapter = address(new AaveV2EtherAdapter(aave, underlying, aToken));
    } else {
      adapter = CloneLibrary.createClone(erc20AdapterImplementation);
      AaveV2Erc20Adapter(adapter).initialize(underlying, aToken);
    }
  }

/* ========== Public Queries ========== */

  function protocol() external pure virtual override returns (string memory) {
    return "Aave V2";
  }

  function getUnmapped() public view virtual override returns (address[] memory tokens) {
    tokens = pool.getReservesList();
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
    return pool.getConfiguration(underlying).isFrozen();
  }
}

