pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./UniswapV2Library.sol";
import "./Operator.sol";

contract StableFund is Operator {
    IUniswapV2Pair public pair;
    IERC20 public tokenA;
    IERC20 public tokenB;
    IUniswapV2Router02 public router;
    address public trader;
    bool public migrated = false;

    constructor(
        address _tokenA,
        address _tokenB,
        address _factory,
        address _router,
        address _trader
    ) public {
        pair = IUniswapV2Pair(
            UniswapV2Library.pairFor(_factory, _tokenA, _tokenB)
        );
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        router = IUniswapV2Router02(_router);
        trader = _trader;
    }

    modifier onlyAllowedTokens(address[] calldata path) {
        require(
            (path[0] == address(tokenA) &&
                path[path.length - 1] == address(tokenB)) ||
                (path[0] == address(tokenB) &&
                    path[path.length - 1] == address(tokenA)),
            'StableFund: tokens are not allowed'
        );
        _;
    }

    modifier onlyTrader() {
        require(msg.sender == trader, 'sender is not trader');
        _;
    }

    modifier checkMigration {
        require(!migrated, 'StableFund: migrated');

        _;
    }

    /* ========== TRADER ========== */

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) public onlyAllowedTokens(path) onlyTrader checkMigration {
        router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) public onlyAllowedTokens(path) onlyTrader checkMigration {
        router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            deadline
        );
    }

    function approve(address token, uint256 amount)
        public
        onlyTrader
        checkMigration
        returns (bool)
    {
        if (token == address(tokenA)) {
            return tokenA.approve(address(router), amount);
        } else {
            require(
                token == address(tokenB),
                'StableFund: token should match either tokenA or tokenB'
            );
            return tokenB.approve(address(router), amount);
        }
    }

    /* ========== OPERATOR ========== */

    function setTrader(address _trader) public onlyOperator checkMigration {
        trader = _trader;
    }

    /* ========== OWNER ========== */

    function migrate(address target) public onlyOwner checkMigration {
        IERC20(tokenA).transfer(
            target,
            IERC20(tokenA).balanceOf(address(this))
        );

        IERC20(tokenB).transfer(
            target,
            IERC20(tokenB).balanceOf(address(this))
        );

        migrated = true;
        emit Migration(target);
    }

    event Migration(address indexed target);
}
