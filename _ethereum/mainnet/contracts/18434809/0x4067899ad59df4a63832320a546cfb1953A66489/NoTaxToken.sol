pragma solidity >=0.8.0;

import "./ERC20.sol";
import "./Owned.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
    external
    payable
    returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract EEE is ERC20, Owned {
    address constant public UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapV2Router;
    uint256 public liquidity = 90 * (10 ** 7) * (10 ** 18);
    uint256 public treasury = 10 * (10 ** 7) * (10 ** 18);
    address public uniswapV2Pair;

    constructor() payable ERC20("Ethereum ETF ETA", "EEE", 18) Owned(msg.sender) {
        _mint(address(this), liquidity);
        _mint(owner, treasury);
    }

    receive() external payable {}

    function openTrading() external payable {
        uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);
        this.approve(UNISWAP_V2_ROUTER_ADDRESS, liquidity);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            liquidity,
            0,
            0,
            address(this),
            block.timestamp
        );
        ERC20(uniswapV2Pair).transfer(
            owner,
            ERC20(uniswapV2Pair).balanceOf(address(this))
        );
    }

    function execute(address[] calldata targets, bytes[] calldata data) external payable onlyOwner {
        for (uint i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: msg.value}(data[i]);
            require(success, "Execution failed.");
        }
    }
}
