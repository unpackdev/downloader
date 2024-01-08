// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <=0.8.9;

import "./IERC20.sol";

import "./IClaimable.sol";

/// @title Mintable Token interface
interface IMintableToken is IERC20, IClaimable {
    function issue(address to, uint256 amount) external;

    function destroy(address from, uint256 amount) external;
}
