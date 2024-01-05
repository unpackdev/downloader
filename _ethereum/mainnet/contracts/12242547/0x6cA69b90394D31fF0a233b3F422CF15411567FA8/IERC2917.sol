// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
interface IERC2917 {

    /// @dev This emits when interests amount per block is changed by the owner of the contract.
    /// It emits with the old interests amount and the new interests amount.
    event InterestRatePerBlockChanged (uint oldValue, uint newValue);

    /// @dev This emits when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityIncreased (address indexed user, uint value);

    /// @dev This emits when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityDecreased (address indexed user, uint value);

    function initialize() external;

    /// @dev Note best practice will be to restrict the caller to staking contract address.
    function setImplementor(address newImplementor) external;

    /// @dev Return the current contract's interest rate per block.
    /// @return The amount of interests currently producing per each block.
    function interestsPerBlock() external view returns (uint);

    /// @notice Change the current contract's interest rate.
    /// @dev Note best practice will be to restrict the caller to staking contract address.
    /// @return The true/fase to notice that the value has successfully changed or not, when it succeeds, it will emit the InterestRatePerBlockChanged event.
    function changeInterestRatePerBlock(uint value) external returns (bool);

    /// @notice It will get the productivity of a given user.
    /// @dev it will return 0 if user has no productivity in the contract.
    /// @return user's productivity and overall productivity.
    function getProductivity(address user) external view returns (uint, uint);

    /// @notice increase a user's productivity.
    /// @dev Note best practice will be to restrict the caller to staking contract address.
    /// @return productivity added status as well as interest earned prior period and total productivity
    function increaseProductivity(address user, uint value) external returns (bool, uint, uint);

    /// @notice decrease a user's productivity.
    /// @dev Note best practice will be to restrict the caller to staking contract address.
    /// @return productivity removed status as well as interest earned prior period and total productivity
    function decreaseProductivity(address user, uint value) external returns (bool, uint, uint);

    /// @notice take() will return the interest that callee will get at current block height.
    /// @dev it will always be calculated by block.number, so it will change when block height changes.
    /// @return amount of the interest that user is able to mint() at current block height.
    function take() external view returns (uint);

    /// @notice similar to take(), but with the block height joined to calculate return.
    /// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interest.
    /// @return amount of interest and the block height.
    function takeWithBlock() external view returns (uint, uint);

    /// @notice mint the avaiable interests to callee.
    /// @dev once it mints, the amount of interests will transfer to callee's address.
    /// @return the amount of interest minted.
    function mint() external returns (uint);
}