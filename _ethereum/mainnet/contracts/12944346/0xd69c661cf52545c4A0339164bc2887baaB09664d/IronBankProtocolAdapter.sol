// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./CompoundInterfaces.sol";
import "./CyErc20Adapter.sol";
import "./CyEtherAdapter.sol";
import "./AbstractProtocolAdapter.sol";


contract IronBankProtocolAdapter is AbstractProtocolAdapter {
  using CloneLibrary for address;

/* ========== Constants ========== */

  IComptroller public constant comptroller = IComptroller(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
  address public immutable erc20AdapterImplementation;
  address public immutable etherAdapterImplementation;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) AbstractProtocolAdapter(_registry) {
    erc20AdapterImplementation = address(new CyErc20Adapter());
    etherAdapterImplementation = address(new CyEtherAdapter());
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
    CyErc20Adapter(adapter).initialize(underlying, address(cToken));
  }

/* ========== Public Queries ========== */

  function protocol() external pure virtual override returns (string memory) {
    return "Iron Bank";
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
    return isTokenMarketFrozen(IErc20Adapter(adapter).token());
  }

  function isTokenMarketFrozen(address cToken) internal view virtual override returns (bool) {
    if (comptroller.mintGuardianPaused(cToken)) {
      return true;
    }
    return IERC20(cToken).totalSupply() == 0;
  }
}