pragma solidity 0.5.16;

import "./Governable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";

import "./IRewardPool.sol";
import "./IUniswapV2Router02.sol";

contract FeeRewardForwarder is Governable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public force;

    address public constant usdc =
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant usdt =
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public constant dai =
        address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address public constant wbtc =
        address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address public constant renBTC =
        address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    address public constant sushi =
        address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    address public constant dego =
        address(0x88EF27e69108B2633F8E1C184CC37940A075cC02);
    address public constant uni =
        address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    address public constant comp =
        address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    address public constant crv =
        address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    address public constant idx =
        address(0x0954906da0Bf32d5479e25f46056d22f08464cab);
    address public constant idle =
        address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);

    address public constant ycrv =
        address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);

    address public constant weth =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    mapping(address => mapping(address => address[])) public uniswapRoutes;
    mapping(address => address) public useSushiswap; // determines which part of the route to liquidate on Sushiswap

    // the targeted reward token to convert everything to
    // initializing so that we do not need to call setTokenPool(...)
    address public targetToken;
    address public profitSharingPool =
        address(0x99414B029Bf6d9B9941BA3f22252aCBD2bE50FD9);

    address public constant uniswapRouterV2 =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant sushiswapRouterV2 =
        address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    event TokenPoolSet(address token, address pool);

    constructor(address _storage, address _force) public Governable(_storage) {
        require(_force != address(0), "_force not defined");
        force = _force;
        targetToken = force;

        // preset for the already in use crops
        uniswapRoutes[weth][force] = [weth, force];
        uniswapRoutes[dai][force] = [dai, weth, force];
        uniswapRoutes[usdc][force] = [usdc, force];
        uniswapRoutes[usdt][force] = [usdt, weth, force];

        uniswapRoutes[wbtc][force] = [wbtc, weth, force];
        uniswapRoutes[renBTC][force] = [renBTC, weth, force];

        // use Sushiswap for SUSHI, convert into WETH
        useSushiswap[sushi] = weth;
        // the name remains uniswapRoutes for simplicity even though the route is actually for Sushiswap
        uniswapRoutes[sushi][weth] = [sushi, weth];

        uniswapRoutes[dego][force] = [dego, weth, force];
        uniswapRoutes[crv][force] = [crv, weth, force];
        uniswapRoutes[comp][force] = [comp, weth, force];

        uniswapRoutes[idx][force] = [idx, weth, force];
        uniswapRoutes[idle][force] = [idle, weth, force];

        //weth
        uniswapRoutes[dai][weth] = [dai, weth];
        uniswapRoutes[usdc][weth] = [usdc, weth];
        uniswapRoutes[usdt][weth] = [usdt, weth];

        uniswapRoutes[wbtc][weth] = [wbtc, weth];
        uniswapRoutes[renBTC][weth] = [renBTC, weth];
        uniswapRoutes[sushi][weth] = [sushi, weth];
        uniswapRoutes[dego][weth] = [dego, weth];
        uniswapRoutes[crv][weth] = [crv, weth];
        uniswapRoutes[comp][weth] = [comp, weth];
        uniswapRoutes[idx][weth] = [idx, weth];
        uniswapRoutes[idle][weth] = [idle, weth];

        // usdc
        uniswapRoutes[weth][usdc] = [weth, usdc];
        uniswapRoutes[dai][usdc] = [dai, weth, usdc];
        uniswapRoutes[usdt][usdc] = [usdt, weth, usdc];

        uniswapRoutes[wbtc][usdc] = [wbtc, weth, usdc];
        uniswapRoutes[renBTC][usdc] = [renBTC, weth, usdc];
        uniswapRoutes[sushi][usdc] = [sushi, weth, usdc];
        uniswapRoutes[dego][usdc] = [dego, weth, usdc];
        uniswapRoutes[crv][usdc] = [crv, weth, usdc];
        uniswapRoutes[comp][usdc] = [comp, weth, usdc];
    }

    /*
     *   Set the pool that will receive the reward token
     *   based on the address of the reward Token
     */
    function setTokenPool(address _pool) public onlyGovernance {
        profitSharingPool = _pool;
        emit TokenPoolSet(targetToken, _pool);
    }

    /**
     * Sets the path for swapping tokens to the to address
     * The to address is not validated to match the targetToken,
     * so that we could first update the paths, and then,
     * set the new target
     */
    function setConversionPath(
        address from,
        address to,
        address[] memory _uniswapRoute
    ) public onlyGovernance {
        require(
            from == _uniswapRoute[0],
            "The first token of the Uniswap route must be the from token"
        );
        require(
            to == _uniswapRoute[_uniswapRoute.length - 1],
            "The last token of the Uniswap route must be the to token"
        );
        uniswapRoutes[from][to] = _uniswapRoute;
    }

    /**
     * Sets whether liquidation happens through Uniswap or Sushiswap
     * Setting to address (0) switches to Uniswap
     */
    function setUseSushiswap(address from, address _value)
        public
        onlyGovernance
    {
        useSushiswap[from] = _value;
    }

    // Transfers the funds from the msg.sender to the pool
    // under normal circumstances, msg.sender is the strategy
    function poolNotifyFixedTarget(address _token, uint256 _amount) external {
        uint256 remainingAmount = _amount;
        // Note: targetToken could only be FORCE or NULL.
        // it is only used to check that the rewardPool is set.
        if (targetToken == address(0)) {
            return; // a No-op if target pool is not set yet
        }
        if (_token == force) {
            // this is already the right token
            // Note: Under current structure, this would be FORCE.
            // designed for NotifyHelper calls
            // This is assuming that NO strategy would notify profits in FORCE
            IERC20(_token).safeTransferFrom(
                msg.sender,
                profitSharingPool,
                _amount
            );
            IRewardPool(profitSharingPool).notifyRewardAmount(_amount);
        } else {
            // we need to convert _token to FORCE
            if (
                uniswapRoutes[_token][force].length > 1 ||
                (useSushiswap[_token] != address(0) &&
                    uniswapRoutes[useSushiswap[_token]][force].length > 1)
            ) {
                IERC20(_token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    remainingAmount
                );
                uint256 balanceToSwap = IERC20(_token).balanceOf(address(this));
                liquidate(_token, force, balanceToSwap);

                // now we can send this token forward
                uint256 convertedRewardAmount =
                    IERC20(force).balanceOf(address(this));
                IERC20(force).safeTransfer(
                    profitSharingPool,
                    convertedRewardAmount
                );
                IRewardPool(profitSharingPool).notifyRewardAmount(
                    convertedRewardAmount
                );
            } else {
                // else the route does not exist for this token
                // do not take any fees and revert.
                // It's better to set the liquidation path then perform it again,
                // rather then leaving the funds in controller
                revert("FeeRewardForwarder: liquidation path doesn't exist");
            }
        }
    }

    function liquidate(
        address _from,
        address _to,
        uint256 balanceToSwap
    ) internal {
        if (balanceToSwap == 0) {
            return;
        }

        if (useSushiswap[_from] != address(0)) {
            address sushiswapDestinationToken = useSushiswap[_from];

            // a special case for Sushiswap, liquidating SUSHI to sushiswapDestinationToken on Sushiswap, and then sushiswapDestinationToken to FORCE on uniswap
            IERC20(_from).safeApprove(sushiswapRouterV2, 0);
            IERC20(_from).safeApprove(sushiswapRouterV2, balanceToSwap);

            IUniswapV2Router02(sushiswapRouterV2).swapExactTokensForTokens(
                balanceToSwap,
                1, // we will accept any amount
                uniswapRoutes[_from][sushiswapDestinationToken],
                address(this),
                block.timestamp
            );

            uint256 remainingWethBalanceToSwap =
                IERC20(sushiswapDestinationToken).balanceOf(address(this));

            IERC20(sushiswapDestinationToken).safeApprove(uniswapRouterV2, 0);
            IERC20(sushiswapDestinationToken).safeApprove(
                uniswapRouterV2,
                remainingWethBalanceToSwap
            );

            IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
                remainingWethBalanceToSwap,
                1, // we will accept any amount
                uniswapRoutes[sushiswapDestinationToken][_to],
                address(this),
                block.timestamp
            );
        } else {
            IERC20(_from).safeApprove(uniswapRouterV2, 0);
            IERC20(_from).safeApprove(uniswapRouterV2, balanceToSwap);

            IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
                balanceToSwap,
                1, // we will accept any amount
                uniswapRoutes[_from][_to],
                address(this),
                block.timestamp
            );
        }
    }
}
