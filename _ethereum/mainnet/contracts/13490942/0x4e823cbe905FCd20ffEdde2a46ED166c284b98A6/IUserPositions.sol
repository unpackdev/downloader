// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;
import "./IStrategyMap.sol";

interface IUserPositions {
    // ##### Structs

    // Virtual balance == total balance - realBalance
    struct TokenBalance {
        uint256 totalBalance;
        uint256 realBalance;
    }

    // ##### Functions

    /// @param biosRewardsDuration_ The duration in seconds for a BIOS rewards period to last
    function setBiosRewardsDuration(uint32 biosRewardsDuration_) external;

    /// @param sender The account seeding BIOS rewards
    /// @param biosAmount The amount of BIOS to add to rewards
    function seedBiosRewards(address sender, uint256 biosAmount) external;

    /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
    function increaseBiosRewards() external;

    /// @notice User is allowed to deposit whitelisted tokens
    /// @param depositor Address of the account depositing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param ethAmount The amount of ETH sent with the deposit
    function deposit(
        address depositor,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 ethAmount
    ) external;

    /// @notice User is allowed to withdraw tokens
    /// @param recipient The address of the user withdrawing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    function withdraw(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bool withdrawWethAsEth
    ) external returns (uint256 ethWithdrawn);

    /// @notice Allows a user to withdraw entire balances of the specified tokens and claim rewards
    /// @param recipient The address of the user withdrawing tokens
    /// @param tokens Array of token address that user is exiting positions from
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    /// @return tokenAmounts The amounts of each token being withdrawn
    /// @return ethWithdrawn The amount of ETH being withdrawn
    /// @return ethClaimed The amount of ETH being claimed from rewards
    /// @return biosClaimed The amount of BIOS being claimed from rewards
    function withdrawAllAndClaim(
        address recipient,
        address[] memory tokens,
        bool withdrawWethAsEth
    )
        external
        returns (
            uint256[] memory tokenAmounts,
            uint256 ethWithdrawn,
            uint256 ethClaimed,
            uint256 biosClaimed
        );

    /// @param user The address of the user claiming ETH rewards
    function claimEthRewards(address user)
        external
        returns (uint256 ethClaimed);

    /// @notice Allows users to claim their BIOS rewards for each token
    /// @param recipient The address of the usuer claiming BIOS rewards
    function claimBiosRewards(address recipient)
        external
        returns (uint256 biosClaimed);

    /// @param asset Address of the ERC20 token contract
    /// @return The total balance of the asset deposited in the system
    function totalTokenBalance(address asset) external view returns (uint256);

    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userTokenBalance(address asset, address account)
        external
        view
        returns (uint256);

    /// @return The Bios Rewards Duration
    function getBiosRewardsDuration() external view returns (uint32);

    /// @notice Transfers tokens to the StrategyMap
    /// @dev This is a ledger adjustment. The tokens remain in the kernel.
    /// @param recipient  The user to transfer funds for
    /// @param tokens  the tokens and amounts to be moved
    function transferToStrategy(
        address recipient,
        IStrategyMap.TokenMovement[] calldata tokens
    ) external;

    /// @notice Transfers tokens from the StrategyMap
    /// @dev This is a ledger adjustment. The tokens remain in the kernel.
    /// @param recipient  The user to transfer funds for
    /// @param tokens  the tokens and amounts to be moved
    function transferFromStrategy(
        address recipient,
        IStrategyMap.TokenMovement[] calldata tokens
    ) external;

    /**
    @notice Returns the amount of tokens a user is owed, but that haven't yet been withdrawn from the integrations
    @param user  The user to retrieve the balance for
    @param token  The token to retrieve the balance for
     */
    function getUserVirtualBalance(address user, address token)
        external
        view
        returns (uint256);
}
