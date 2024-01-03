// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./UniswapBase.sol";

abstract contract LGEBase is UniswapBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(address addressRegistry) internal {
        _setAddressRegistry(addressRegistry);
    }    
}