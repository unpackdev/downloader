// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./IERC20.sol";

/// @notice ICVNX interface for CVNX contract.
interface ICVNX is IERC20 {
    /// @notice Lock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function lock(address _tokenOwner, uint256 _tokenAmount) external;

    /// @notice Unlock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function unlock(address _tokenOwner, uint256 _tokenAmount) external;

    /// @notice Swap CVN to CVNX tokens
    /// @param _amount Token amount to swap
    function swap(uint256 _amount) external returns (bool);

    /// @notice Transfer stuck tokens
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;
}
