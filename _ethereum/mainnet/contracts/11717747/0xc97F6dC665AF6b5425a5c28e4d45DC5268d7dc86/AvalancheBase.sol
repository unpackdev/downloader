// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./LiquidityPoolBase.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

abstract contract AvalancheBase is LiquidityPoolBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(address addressRegistry) internal {
        _setAddressRegistry(addressRegistry);
    }
}