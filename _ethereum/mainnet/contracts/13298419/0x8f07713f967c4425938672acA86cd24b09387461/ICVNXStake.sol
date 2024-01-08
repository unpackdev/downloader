// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

/// @notice ICVNXStake interface for CVNXStake contract.
interface ICVNXStake {
    struct Stake {
        uint256 amount;
        uint256 endTimestamp;
    }

    /// @notice Stake (lock) tokens for period.
    /// @param _amount Token amount
    /// @param _address Token holder address
    /// @param _endTimestamp End  of lock period (seconds)
    function stake(uint256 _amount, address _address, uint256 _endTimestamp) external;

    /// @notice Unstake (unlock) all available for unlock tokens.
    function unstake() external;

    /// @notice Return list of stakes for address.
    /// @param _address Token holder address
    function getStakesList(address _address) external view returns(Stake[] memory stakes);

    /// @notice Return total stake amount for address.
    /// @param _address Token holder address
    function getStakedAmount(address _address) external view returns(uint256);
}
