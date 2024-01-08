// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./CompoundInterfaces.sol";
import "./CrErc20Adapter.sol";
import "./CrEtherAdapter.sol";
import "./AbstractProtocolAdapter.sol";


contract CreamProtocolAdapter is AbstractProtocolAdapter {
  using CloneLibrary for address;

/* ========== Constants ========== */

  IComptroller public constant comptroller = IComptroller(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);
  address public immutable erc20AdapterImplementation;
  address public immutable etherAdapterImplementation;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) AbstractProtocolAdapter(_registry) {
    erc20AdapterImplementation = address(new CrErc20Adapter());
    etherAdapterImplementation = address(new CrEtherAdapter());
  }

/* ========== Internal Actions ========== */

  function deployAdapter(address cToken) internal virtual override returns (address adapter) {
    address underlying;
    // The call to underlying will use all the gas sent if it fails,
    // so we specify a maximum of 25k gas. The contract will only use ~2k
    // but this protects against all likely changes to the gas schedule.
    try ICToken(cToken).underlying{gas: 25000}() returns (address _underlying) {
      underlying = _underlying;
      if (underlying == address(0)) {
        underlying = weth;
      }
    } catch {
      underlying = weth;
    }
    if (underlying == weth) {
      adapter = CloneLibrary.createClone(etherAdapterImplementation);
    } else {
      adapter = CloneLibrary.createClone(erc20AdapterImplementation);
    }
    CrErc20Adapter(adapter).initialize(underlying, address(cToken));
  }

/* ========== Public Queries ========== */

  function protocol() external pure virtual override returns (string memory) {
    return "Cream";
  }

  function getUnmapped() public view virtual override returns (address[] memory cTokens) {
    cTokens = toAddressArray(comptroller.getAllMarkets());
    uint256 len = cTokens.length;
    uint256 prevLen = totalMapped;
    if (len == prevLen) {
      assembly { mstore(cTokens, 0) }
    } else {
      assembly {
        cTokens := add(cTokens, mul(prevLen, 32))
        mstore(cTokens, sub(len, prevLen))
      }
    }
  }

  function toAddressArray(ICToken[] memory cTokens) internal pure returns (address[] memory arr) {
    assembly { arr := cTokens }
  }

/* ========== Internal Queries ========== */

  function isAdapterMarketFrozen(address adapter) internal view virtual override returns (bool) {
    return comptroller.mintGuardianPaused(IErc20Adapter(adapter).token());
  }

  function isTokenMarketFrozen(address cToken) internal view virtual override returns (bool) {
    // Return true if market is paused in comptroller
    bool isFrozen = comptroller.mintGuardianPaused(cToken);
    if (isFrozen) return true;
    // Return true if market is for an SLP token, which the adapter can not handle.
    // The call to `sushi()` will use all the gas sent if it fails, so we specify a
    // maximum of 25k gas to ensure it will not use all the gas in the transaction, but
    // can still be executed with any foreseeable changes to the gas schedule.
    try ICToken(cToken).sushi{gas:25000}() returns (address) {
      return true;
    } catch {
      // Return true is supply is 0.
      return IERC20(cToken).totalSupply() == 0;
    }
  }
}