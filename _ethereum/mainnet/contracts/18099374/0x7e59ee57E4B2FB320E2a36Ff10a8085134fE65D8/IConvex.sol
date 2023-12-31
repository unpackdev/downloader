// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the Convex Booster contract
interface IConvexBoosterL1 {
    /// @notice Deposits funds into the booster
    /// @param pid The pool ID
    /// @param amount The amount to deposit
    /// @param stake Flag indicating whether to stake the deposited funds
    /// @return True if the deposit was successful
    function deposit(uint256 pid, uint256 amount, bool stake) external returns (bool);

    /// @notice Returns the address of the CVX token
    function minter() external view returns (address);

    /// @notice Earmarks rewards for the specified pool
    /// @param _pid The pool ID
    function earmarkRewards(uint256 _pid) external;

    /// @notice Retrieves information about a pool
    /// @param pid The pool ID
    /// @return lptoken The LP token address
    /// @return token The token address
    /// @return gauge The gauge address
    /// @return crvRewards The CRV rewards address
    /// @return stash The stash address
    /// @return shutdown Flag indicating if the pool is shutdown
    function poolInfo(
        uint256 pid
    )
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );
}

/// @notice Interface for the Convex Booster L2 contract
interface IConvexBoosterL2 {
    /// @notice Deposits funds into the L2 booster
    /// @param _pid The pool ID
    /// @param _amount The amount to deposit
    /// @return True if the deposit was successful
    function deposit(uint256 _pid, uint256 _amount) external returns (bool);

    /// @notice Deposits all available funds into the L2 booster
    /// @param _pid The pool ID
    /// @return True if the deposit was successful
    function depositAll(uint256 _pid) external returns (bool);

    /// @notice Retrieves information about a pool
    /// @param pid The pool ID
    /// @return lptoken The LP token address
    /// @return gauge The gauge address
    /// @return rewards The rewards address
    /// @return shutdown Flag indicating if the pool is shutdown
    /// @return factory The curve factory address used to create the pool
    function poolInfo(
        uint256 pid
    )
        external
        view
        returns (
            address lptoken, //the curve lp token
            address gauge, //the curve gauge
            address rewards, //the main reward/staking contract
            bool shutdown, //is this pool shutdown?
            address factory //a reference to the curve factory used to create this pool (needed for minting crv)
        );
}

interface IConvexRewardPoolL1 {
    /// @notice Retrieves the balance of the specified account
    /// @param account The account address
    /// @return The account balance
    function balanceOf(address account) external view returns (uint256);

    /// @notice Retrieves the claimable rewards for the specified account
    /// @param _account The account address
    /// @return the amount representing the claimable rewards
    function earned(address _account) external view returns (uint256);

    /// @dev Calculates the reward in CVX based on the reward of CRV
    /// @dev Used for mock purposes only
    /// @param _crvAmount The amount of CRV amount.
    /// @return returns the amount of cvx rewards to get
    function getCVXAmount(uint256 _crvAmount) external view returns (uint256);

    /// @notice Retrieves the period finish timestamp
    /// @return The period finish timestamp
    function periodFinish() external view returns (uint256);

    /// @notice Claims the available rewards for the caller
    function getReward() external;

    /// @notice Gets the address of the reward token
    function rewardToken() external view returns (address);

    /// @notice Withdraws and unwraps the specified amount of tokens
    /// @param _amount The amount to withdraw and unwrap
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAndUnwrap(uint256 _amount, bool claim) external;

    /// @notice Withdraws all funds and unwraps the tokens
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAllAndUnwrap(bool claim) external;
}

/// @notice Interface for the Convex Reward Pool L2 contract
interface IConvexRewardPoolL2 {
    /// @notice Struct containing information about an earned reward
    struct EarnedData {
        address token;
        uint256 amount;
    }

    /// @notice Retrieves the balance of the specified account
    /// @param account The account address
    /// @return The account balance
    function balanceOf(address account) external view returns (uint256);

    /// @notice Retrieves the claimable rewards for the specified account
    /// @param _account The account address
    /// @return claimable An array of EarnedData representing the claimable rewards
    function earned(address _account) external returns (EarnedData[] memory claimable);

    /// @notice Retrieves the period finish timestamp
    /// @return The period finish timestamp
    function periodFinish() external view returns (uint256);

    /// @notice Claims the available rewards for the specified account
    /// @param _account The account address
    function getReward(address _account) external;

    /// @notice Withdraws the specified amount of tokens
    /// @param _amount The amount to withdraw
    /// @param _claim Flag indicating whether to claim rewards
    function withdraw(uint256 _amount, bool _claim) external;

    /// @notice Withdraws all funds
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAll(bool claim) external;
}
