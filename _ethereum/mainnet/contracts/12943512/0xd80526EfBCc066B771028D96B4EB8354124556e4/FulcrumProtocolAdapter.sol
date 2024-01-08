// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./FulcrumInterfaces.sol";
import "./FulcrumErc20Adapter.sol";
import "./FulcrumEtherAdapter.sol";
import "./IAdapterRegistry.sol";
import "./AbstractProtocolAdapter.sol";


contract FulcrumProtocolAdapter is AbstractProtocolAdapter {

/* ========== Constants ========== */

  IBZX public constant bzx = IBZX(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);
  address public immutable erc20AdapterImplementation;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) AbstractProtocolAdapter(_registry) {
    address _erc20AdapterImplementation = address(new FulcrumErc20Adapter());
    erc20AdapterImplementation = _erc20AdapterImplementation;

    address[] memory loanPoolsZeroAndOne = bzx.getLoanPoolsList(0, 2);
    address underlying0 = bzx.loanPoolToUnderlying(loanPoolsZeroAndOne[0]);
    address adapter0 = CloneLibrary.createClone(_erc20AdapterImplementation);
    FulcrumErc20Adapter(adapter0).initialize(underlying0, loanPoolsZeroAndOne[0]);

    _registry.addTokenAdapter(adapter0);
    _registry.addTokenAdapter(address(new FulcrumEtherAdapter(weth, loanPoolsZeroAndOne[1])));

    totalMapped = 2;
  }

/* ========== Internal Actions ========== */

  function deployAdapter(address loanPool) internal virtual override returns (address adapter) {
    address underlying = bzx.loanPoolToUnderlying(loanPool);
    adapter = CloneLibrary.createClone(erc20AdapterImplementation);
    FulcrumErc20Adapter(adapter).initialize(underlying, loanPool);
  }

/* ========== Public Queries ========== */

  function protocol() external pure virtual override returns (string memory) {
    return "Fulcrum";
  }

  function getUnmapped() public view virtual override returns (address[] memory loanPools) {
    loanPools = bzx.getLoanPoolsList(totalMapped, 1e18);
  }

  function getUnmappedUpTo(uint256 max) public view virtual override returns (address[] memory loanPools) {
    loanPools = bzx.getLoanPoolsList(totalMapped, max);
  }

/* ========== Internal Queries ========== */

  function isAdapterMarketFrozen(address adapter) internal view virtual override returns (bool) {
    return isTokenMarketFrozen(IErc20Adapter(adapter).token());
  }

  function isTokenMarketFrozen(address loanPool) internal view virtual override returns (bool) {
    return IERC20(loanPool).totalSupply() == 0;
  }
}