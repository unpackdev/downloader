// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;
import "./SafeERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

//https://arbiscan.io/address/0xba12222222228d8ba445958a75a0704d566bf2c8#code - see IVault.sol
interface IVault {
    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData; // For joins, userData encodes a JoinKind to tell the pool what style of join you're performing.
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData; // For exits, userData encodes a ExitKind to tell the pool what style of join you're performing.
        bool toInternalBalance; // True if you receiving tokens as internal token balances. False if receiving as ERC20.
    }

    // https://docs.balancer.fi/reference/joins-and-exits/pool-joins.html#userdata
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    //https://docs.balancer.fi/reference/joins-and-exits/pool-exits.html#userdata
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }

    enum StableExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        EXACT_BPT_IN_FOR_ALL_TOKENS_OUT
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// https://arbiscan.io/address/0x251e51b25afa40f2b6b9f05aaf1bc7eaa0551771#code
interface IRewardsGauge {
    function deposit(uint256 _value) external;

    // this defaults to not claiming the rewards
    // withdraw(_value: uint256, _claim_rewards: bool = False):
    function withdraw(uint256 _value) external;

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function reward_tokens(uint256 _index) external view returns (address);

    function reward_balances(address token) external view returns (uint256);

    function reward_integral(address token) external view returns (uint256);

    function reward_integral_for(address token, address user) external view returns (uint256);

    function reward_contract() external view returns (IRewardsContract);

    function claimable_reward(address _addr, address _token) external view returns (uint256);
}

interface IRewardsContract {
    struct RewardToken {
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 duration;
        uint256 received;
        uint256 paid;
    }

    function get_reward() external;

    function reward_data(address _token) external view returns (RewardToken memory);

    function reward_tokens(uint256 index) external view returns (address);

    function last_update_time() external view returns (uint256);
}

//https://arbiscan.io/address/0xa0dabebaad1b243bbb243f933013d560819eb66f#writeContract
interface IChildChainGaugeRewardHelper {
    function claimRewardsFromGauge(address gauge, address user) external;
}
