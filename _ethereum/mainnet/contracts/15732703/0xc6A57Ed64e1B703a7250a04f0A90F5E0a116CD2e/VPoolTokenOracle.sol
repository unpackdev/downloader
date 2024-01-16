// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20Metadata.sol";
import "./IOracle.sol";
import "./ITokenOracle.sol";
import "./IVesperPool.sol";

/**
 * @title Oracle for vPool token
 */
contract VPoolTokenOracle is ITokenOracle {
    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address token_) external view override returns (uint256 _priceInUsd) {
        IVesperPool _vToken = IVesperPool(token_);
        address _underlyingAddress = _vToken.token();
        _priceInUsd =
            (IOracle(msg.sender).getPriceInUsd(_underlyingAddress) * _vToken.pricePerShare()) /
            10**IERC20Metadata(_underlyingAddress).decimals();
    }
}
