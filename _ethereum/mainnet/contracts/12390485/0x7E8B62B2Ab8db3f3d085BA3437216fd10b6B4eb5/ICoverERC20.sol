// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @title CoverERC20 contract interface, implements {IERC20}. See {CoverERC20}.
 * @author crypto-pumpkin
 */
interface ICoverERC20 is IERC20 {
    /// @notice access restriction - owner (Cover)
    function mint(address _account, uint256 _amount) external returns (bool);
    function burnByCover(address _account, uint256 _amount) external returns (bool);
}