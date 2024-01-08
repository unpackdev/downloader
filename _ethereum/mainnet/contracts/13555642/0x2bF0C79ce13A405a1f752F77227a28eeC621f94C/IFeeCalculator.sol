// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IFeeCalculator {
    /// @notice An event emitted once the service fee is modified
    event ServiceFeeSet(address account, address token, uint256 newServiceFee);
    /// @notice An event emitted once a member claims fees accredited to him
    event Claim(
        address indexed member,
        address indexed memberAdmin,
        address token,
        uint256 amount
    );

    /// @notice Construct a new FeeCalculator contract
    /// @param _precision The precision for every fee calculator
    function initFeeCalculator(uint256 _precision) external;

    /// @return The current precision for service fee calculations of tokens
    function serviceFeePrecision() external view returns (uint256);

    /// @notice Sets the service fee for a token
    /// @param _token The target token
    /// @param _serviceFeePercentage The new service fee percentage
    function setServiceFee(address _token, uint256 _serviceFeePercentage)
        external;

    /// @notice Returns all data for a specific native fee calculator
    /// @param _token The target token
    /// @return serviceFeePercentage The current service fee
    /// @return feesAccrued Total fees accrued since contract deployment
    /// @return previousAccrued Total fees accrued up to the last point a member claimed rewards
    /// @return accumulator Accumulates rewards on a per-member basis
    function tokenFeeData(address _token)
        external
        view
        returns (
            uint256 serviceFeePercentage,
            uint256 feesAccrued,
            uint256 previousAccrued,
            uint256 accumulator
        );

    /// @param _account The address of a validator
    /// @param _token The token address
    /// @return The total amount claimed by the provided validator address for the specified token
    function claimedRewardsPerAccount(address _account, address _token)
        external
        view
        returns (uint256);

    /// @notice Sends out the reward accumulated by the member for the specified token
    /// to the member admin
    function claim(address _token, address _member) external;
}
