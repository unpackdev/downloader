// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20Metadata.sol";
import "./ICToken.sol";
import "./IOracle.sol";
import "./ITokenOracle.sol";

/**
 * @title Oracle for `CTokens`
 */
contract CTokenOracle is ITokenOracle {
    uint256 public constant ONE_CTOKEN = 1e8;

    /**
     * @notice The address of the `CEther` underlying (Usually WETH)
     */
    address public immutable wethLike;

    constructor(address _wethLike) {
        require(_wethLike != address(0), "weth-like-null");
        wethLike = _wethLike;
    }

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address _asset) external view returns (uint256 _priceInUsd) {
        address _underlyingAddress;
        // Note: Compound's `CEther` hasn't the `underlying()` function, forks may return `address(0)` (e.g. RariFuse)
        try ICToken(_asset).underlying() returns (address _underlying) {
            _underlyingAddress = _underlying;
        } catch {}

        if (_underlyingAddress == address(0)) {
            _underlyingAddress = wethLike;
        }
        uint256 _underlyingPriceInUsd = IOracle(msg.sender).getPriceInUsd(_underlyingAddress);
        uint256 _underlyingAmount = (ONE_CTOKEN * ICToken(_asset).exchangeRateStored()) / 1e18;
        _priceInUsd = (_underlyingPriceInUsd * _underlyingAmount) / 10**IERC20Metadata(_underlyingAddress).decimals();
    }
}
