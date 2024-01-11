// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./MToken.sol";
import "./ErrorCodes.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./IUniswapV2Router02.sol";

contract DeadDrop is AccessControl {
    using SafeERC20 for IERC20;

    /// @notice Whitelist for markets allowed as a withdrawal destination.
    mapping(IERC20 => MToken) public allowedMarkets;
    /// @notice Whitelist for swap routers
    mapping(IUniswapV2Router02 => bool) public allowedSwapRouters;
    /// @notice Whitelist for users who can be a withdrawal recipients
    mapping(address => bool) public allowedWithdrawReceivers;
    /// @notice Whitelist for bots
    mapping(address => bool) public allowedBots;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GUARDIAN = bytes32(0x8b5b16d04624687fcf0d0228f19993c9157c1ed07b41d8d430fd9100eb099fe8);

    event WithdrewToProtocolInterest(uint256 amount, IERC20 token, MToken market);
    event SwapTokensForExactTokens(
        uint256 amountInMax,
        uint256 amountInActual,
        uint256 amountOut,
        IUniswapV2Router02 router,
        address[] path,
        uint256 deadline
    );
    event SwapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 amountOutActual,
        IUniswapV2Router02 router,
        address[] path,
        uint256 deadline
    );
    event Withdraw(address token, address to, uint256 amount);
    event NewAllowedSwapRouter(IUniswapV2Router01 router);
    event NewAllowedWithdrawReceiver(address receiver);
    event NewAllowedBot(address bot);
    event NewAllowedMarket(IERC20 token, MToken market);
    event AllowedSwapRouterRemoved(IUniswapV2Router01 router);
    event AllowedWithdrawReceiverRemoved(address receiver);
    event AllowedBotRemoved(address bot);
    event AllowedMarketRemoved(IERC20 token, MToken market);

    constructor(address admin_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GUARDIAN, admin_);
    }

    /************************************************************************/
    /*                          BOT FUNCTIONS                               */
    /************************************************************************/

    /**
     * @notice Withdraw underlying asset to market's protocol interest
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     */
    //slither-disable-next-line reentrancy-events
    function withdrawToProtocolInterest(uint256 amount, IERC20 underlying) external onlyRole(GUARDIAN) {
        MToken market = allowedMarkets[underlying];
        require(address(market) != address(0), ErrorCodes.DD_UNSUPPORTED_TOKEN);

        underlying.safeIncreaseAllowance(address(market), amount);
        market.addProtocolInterest(amount);
        emit WithdrewToProtocolInterest(amount, underlying, market);
    }

    /**
     * @dev Wrapper over UniswapV2Router02 swapTokensForExactTokens()
     * @notice Withdraw token[0], change to token[1] on DEX and send result to market's protocol interest
     * @param amountInMax Max amount to swap
     * @param amountOut Exact amount to swap for
     * @param path Swap path 0 - source token, n - destination token
     * @param router UniswapV2Router02 router
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    //slither-disable-next-line reentrancy-events
    function swapTokensForExactTokens(
        uint256 amountInMax,
        uint256 amountOut,
        address[] memory path,
        IUniswapV2Router02 router,
        uint256 deadline
    ) external onlyRole(GUARDIAN) allowedRouter(router) {
        require(deadline >= block.timestamp, ErrorCodes.DD_EXPIRED_DEADLINE);
        IERC20 tokenIn = IERC20(path[0]);

        uint256 tokenInBalance = tokenIn.balanceOf(address(this));
        require(tokenInBalance >= amountInMax, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        tokenIn.safeIncreaseAllowance(address(router), amountInMax);
        //slither-disable-next-line unused-return
        router.swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);

        uint256 newTokenInBalance = tokenIn.balanceOf(address(this));

        emit SwapTokensForExactTokens(
            amountInMax,
            tokenInBalance - newTokenInBalance,
            amountOut,
            router,
            path,
            deadline
        );
    }

    /**
     * @dev Wrapper over UniswapV2Router02 swapExactTokensForTokens()
     * @notice Withdraw token[0], change to token[1] on DEX and send result to market's protocol interest
     * @param amountIn Exact amount to swap
     * @param amountOutMin Min amount to swap for
     * @param path Swap path 0 - source token, n - destination token
     * @param router UniswapV2Router02 router
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    //slither-disable-next-line reentrancy-events
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        IUniswapV2Router02 router,
        uint256 deadline
    ) external onlyRole(GUARDIAN) allowedRouter(router) {
        require(deadline >= block.timestamp, ErrorCodes.DD_EXPIRED_DEADLINE);
        uint256 pathLength = path.length;
        IERC20 tokenIn = IERC20(path[0]);
        IERC20 tokenOut = IERC20(path[pathLength - 1]);

        require(tokenIn.balanceOf(address(this)) >= amountIn, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        uint256 tokenOutBalance = tokenOut.balanceOf(address(this));

        tokenIn.safeIncreaseAllowance(address(router), amountIn);
        //slither-disable-next-line unused-return
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);

        uint256 newTokenOutBalance = tokenOut.balanceOf(address(this));
        uint256 amountOutActual = newTokenOutBalance - tokenOutBalance;

        emit SwapExactTokensForTokens(amountIn, amountOutMin, amountOutActual, router, path, deadline);
    }

    /************************************************************************/
    /*                        ADMIN FUNCTIONS                               */
    /************************************************************************/

    /* --- LOGIC --- */

    /**
     * @notice Withdraw tokens to the wallet
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @param to Receipient address
     */
    //slither-disable-next-line reentrancy-events
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) allowedReceiversOnly(to) {
        require(underlying.balanceOf(address(this)) >= amount, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        underlying.safeTransfer(to, amount);
        emit Withdraw(address(underlying), to, amount);
    }

    /* --- SETTERS --- */

    /// @notice Add new market to the whitelist
    function addAllowedMarket(MToken market) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(market) != address(0), ErrorCodes.DD_MARKET_ADDRESS_IS_ZERO);
        require(
            market.supportsInterface(type(MTokenInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );
        allowedMarkets[market.underlying()] = market;
        emit NewAllowedMarket(market.underlying(), market);
    }

    /// @notice Add new IUniswapV2Router02 router to the whitelist
    function addAllowedRouter(IUniswapV2Router02 router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(router) != address(0), ErrorCodes.DD_ROUTER_ADDRESS_IS_ZERO);
        require(!allowedSwapRouters[router], ErrorCodes.DD_ROUTER_ALREADY_SET);
        allowedSwapRouters[router] = true;
        emit NewAllowedSwapRouter(router);
    }

    /// @notice Add new withdraw receiver address to the whitelist
    function addAllowedReceiver(address receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(receiver != address(0), ErrorCodes.DD_RECEIVER_ADDRESS_IS_ZERO);
        require(!allowedWithdrawReceivers[receiver], ErrorCodes.DD_RECEIVER_ALREADY_SET);
        allowedWithdrawReceivers[receiver] = true;
        emit NewAllowedWithdrawReceiver(receiver);
    }

    /// @notice Add new bot address to the whitelist
    function addAllowedBot(address bot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bot != address(0), ErrorCodes.DD_BOT_ADDRESS_IS_ZERO);
        require(!allowedBots[bot], ErrorCodes.DD_BOT_ALREADY_SET);
        allowedBots[bot] = true;
        emit NewAllowedBot(bot);
    }

    /* --- REMOVERS --- */

    /// @notice Remove market from the whitelist
    function removeAllowedMarket(IERC20 underlying) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MToken market = allowedMarkets[underlying];
        require(address(market) != address(0), ErrorCodes.DD_MARKET_NOT_FOUND);
        delete allowedMarkets[underlying];
        emit AllowedMarketRemoved(underlying, market);
    }

    /// @notice Remove IUniswapV2Router02 router from the whitelist
    function removeAllowedRouter(IUniswapV2Router02 router)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        allowedRouter(router)
    {
        delete allowedSwapRouters[router];
        emit AllowedSwapRouterRemoved(router);
    }

    /// @notice Remove withdraw receiver address from the whitelist
    function removeAllowedReceiver(address receiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        allowedReceiversOnly(receiver)
    {
        delete allowedWithdrawReceivers[receiver];
        emit AllowedWithdrawReceiverRemoved(receiver);
    }

    /// @notice Remove withdraw bot address from the whitelist
    function removeAllowedBot(address bot) external onlyRole(DEFAULT_ADMIN_ROLE) allowedBotsOnly(bot) {
        delete allowedBots[bot];
        emit AllowedBotRemoved(bot);
    }

    /************************************************************************/
    /*                          INTERNAL FUNCTIONS                          */
    /************************************************************************/

    modifier allowedRouter(IUniswapV2Router02 router) {
        require(allowedSwapRouters[router], ErrorCodes.DD_ROUTER_NOT_FOUND);
        _;
    }

    modifier allowedReceiversOnly(address receiver) {
        require(allowedWithdrawReceivers[receiver], ErrorCodes.DD_RECEIVER_NOT_FOUND);
        _;
    }

    modifier allowedBotsOnly(address bot) {
        require(allowedBots[bot], ErrorCodes.DD_BOT_NOT_FOUND);
        _;
    }
}
