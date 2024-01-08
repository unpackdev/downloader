//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IFeeCalculator {
    /// @notice An event emitted once the service fee is modified
    event ServiceFeeSet(address account, uint256 newServiceFee);
    /// @notice An event emitted once a member claims fees accredited to him
    event Claim(address member, uint256 amount);

    /**
     *  @notice Construct a new FeeCalculator contract
     *  @param _serviceFee The initial service fee in ALBT tokens (flat)
     */
    function initFeeCalculator(uint256 _serviceFee) external;

    /// @return The currently set service fee
    function serviceFee() external view returns (uint256);

    /**
     *  @notice Sets the service fee for this chain
     *  @param _serviceFee The new service fee
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function setServiceFee(uint256 _serviceFee, bytes[] calldata _signatures) external;

    /// @return The current feesAccrued counter
    function feesAccrued() external view returns (uint256);

    /// @return The feesAccrued counter before the last reward distribution
    function previousAccrued() external view returns (uint256);

    /// @return The current accumulator counter
    function accumulator() external view returns (uint256);

    /**
     *  @param _account The address of a validator
     *  @return The total amount of ALBT claimed by the provided validator address
     */
    function claimedRewardsPerAccount(address _account) external view returns (uint256);

    /// @notice Sends out the reward in ALBT accumulated by the caller
    function claim() external;
}