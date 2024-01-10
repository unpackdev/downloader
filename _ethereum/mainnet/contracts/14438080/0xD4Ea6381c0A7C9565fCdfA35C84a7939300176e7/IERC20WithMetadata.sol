// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

import "./IERC20.sol";

/// @title   ERC20 Interface with metadata
/// @author  Primitive
interface IERC20WithMetadata is IERC20 {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);
}
