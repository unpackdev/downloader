// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @uniswap/v3-periphery/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;


library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: @uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// File: contracts/WhaleSync.sol


pragma solidity ^0.8.20;




interface IWETH9 is IERC20 {
    function withdraw(uint256) external;
}

contract WhaleSync {
    address constant ETH_CONTRACT_ADDRESS =
        0x0000000000000000000000000000000000000000;

    address public immutable owner;
    address public immutable WETH_CONTRACT_ADDRESS;
    IWETH9 public immutable weth;
    ISwapRouter public immutable swapRouter;

    mapping(address => mapping(address => uint256)) private balances_per_user;
    mapping(address => address[]) private tokens_per_user;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(ISwapRouter _swapRouter, address _wethContract) {
        owner = msg.sender;
        weth = IWETH9(_wethContract);
        swapRouter = _swapRouter;
        WETH_CONTRACT_ADDRESS = _wethContract;
    }

    function getTokens() public view returns (address[] memory tokens) {
        return tokens_per_user[msg.sender];
    }

    function getBalance(address token) public view returns (uint256 balance) {
        return balances_per_user[msg.sender][token];
    }

    receive() external payable {
        if (msg.sender != 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            _add_token_balance(msg.sender, msg.value, ETH_CONTRACT_ADDRESS);
        }
    }

    fallback() external payable {}

    function withdrawToken(uint256 amount, address token) public {
        require(
            amount <= balances_per_user[msg.sender][token],
            "Insufficient balance"
        );

        TransferHelper.safeTransferFrom(
            token,
            address(this),
            msg.sender,
            amount
        );

        balances_per_user[msg.sender][token] -= amount;
    }

    function withdrawEth(uint256 amount) public payable {
        require(
            amount <= balances_per_user[msg.sender][ETH_CONTRACT_ADDRESS],
            "Insufficient balance"
        );
        require(amount <= address(this).balance, "C: Insufficient balance");

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");

        balances_per_user[msg.sender][ETH_CONTRACT_ADDRESS] -= amount;
    }

    /*
     *  Private Functions ----------------------------------------------------
     */

    function _add_token_to_user(address user, address token) private {
        address[] memory tokens = tokens_per_user[user];

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                return;
            }
        }

        tokens_per_user[user].push(token);
    }

    function _add_token_balance(
        address user,
        uint256 amount,
        address token
    ) private {
        _add_token_to_user(user, token);

        balances_per_user[user][token] += amount;
    }

    /*
     *  Owner Functions ----------------------------------------------------
     */

    function buy(
        address user,
        address token,
        uint256 amount,
        uint256 fee
    ) external payable isOwner {
        require(
            balances_per_user[user][ETH_CONTRACT_ADDRESS] >= amount + fee,
            "swap: Insufficent funds"
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH_CONTRACT_ADDRESS,
                tokenOut: token,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 15,
                amountIn: amount,
                amountOutMinimum: 1,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle{value: amount}(params);

        balances_per_user[user][ETH_CONTRACT_ADDRESS] -= (amount + fee);
        _add_token_balance(user, amountOut, token);

        (bool sent, ) = payable(owner).call{value: fee}("");
        require(sent, "Failed to send Ether");
    }

    function sell(
        address user,
        address token,
        uint256 amount,
        uint256 fee
    ) external isOwner {
        require(
            balances_per_user[user][token] >= amount,
            "swap: Insufficent funds"
        );

        TransferHelper.safeApprove(token, address(swapRouter), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token,
                tokenOut: WETH_CONTRACT_ADDRESS,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 15,
                amountIn: amount,
                amountOutMinimum: 1,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle(params);

        TransferHelper.safeApprove(
            WETH_CONTRACT_ADDRESS,
            WETH_CONTRACT_ADDRESS,
            amountOut
        );
        IWETH9(WETH_CONTRACT_ADDRESS).withdraw(amountOut);

        require(amountOut - fee > 0, "swap fee: Insufficent funds");

        balances_per_user[user][token] -= amount;
        balances_per_user[user][ETH_CONTRACT_ADDRESS] += (amountOut - fee);

        (bool sent, ) = payable(owner).call{value: fee}("");
        require(sent, "Failed to send Ether");
    }

    function ownerGetTokens(
        address user
    ) public view isOwner returns (address[] memory tokens) {
        return tokens_per_user[user];
    }

    function ownerGetBalance(
        address user,
        address token
    ) public view isOwner returns (uint256 balance) {
        return balances_per_user[user][token];
    }
}