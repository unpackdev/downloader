// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

import "./IBaseOracle.sol";

import "./TickMath.sol";
import "./FullMath.sol";

import "./DefaultAccessControl.sol";
import "./IMEVProtection.sol";

abstract contract CLMMPoolOracle is IBaseOracle, DefaultAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    error PoolNotFound();
    error PoolIsNotStable();
    error InvalidLength();

    uint256 public constant Q96 = 2 ** 96;

    mapping(address => address) public poolForToken;
    EnumerableSet.AddressSet private _supportedTokens;
    IMEVProtection public mevProtection;

    constructor(address admin, IMEVProtection mevProtection_) DefaultAccessControl(admin) {
        mevProtection = mevProtection_;
    }

    function setPools(address[] memory tokens, address[] memory pools) external {
        _requireAdmin();
        if (tokens.length != pools.length) revert InvalidLength();
        for (uint256 i = 0; i < tokens.length; i++) {
            poolForToken[tokens[i]] = pools[i];
            if (pools[i] == address(0)) {
                _supportedTokens.remove(tokens[i]);
            } else {
                _supportedTokens.add(tokens[i]);
            }
        }
    }

    function supportedTokens() public view returns (address[] memory) {
        return _supportedTokens.values();
    }

    function getPriceAndOtherToken(
        address token,
        address pool
    ) public view virtual returns (uint256 priceX96, address tokenOut);

    function quote(
        address token,
        uint256 amount,
        bytes memory securityParams
    ) public view override returns (address[] memory tokens, uint256[] memory tokenAmounts) {
        address pool = poolForToken[token];
        mevProtection.ensureNoMEV(pool, securityParams);
        if (pool == address(0)) revert PoolNotFound();

        tokenAmounts = new uint256[](1);
        tokens = new address[](1);
        (uint256 priceX96, address tokenOut) = getPriceAndOtherToken(token, pool);
        tokenAmounts[0] = FullMath.mulDiv(amount, priceX96, Q96);
        tokens[0] = tokenOut;
    }
}
