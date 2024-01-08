pragma solidity =0.7.6;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./UniswapV2Library.sol";

contract ExchangeRouter {

    address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event BeeSwap(
        address sender,
        address tokenIn,
        address tokenOut,
        uint256 tokenInAmount,
        uint256 tokenOutAmount,
        uint256 timeStamp
    );

    function swapV2Router(
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline,
        address[] calldata path,
        uint8 option
    ) external payable {
        require(path.length >= 2, "RouterInteraction:: Invalid Path length");
        require(
            path[0] != address(0) || path[path.length - 1] != address(0),
            "RouterInteraction:: Invalid token address"
        );

        address sender = msg.sender;
        uint[] memory amounts;

        if (option == 0) {
            IERC20(path[0]).transferFrom(sender, address(this), amountIn);
            IERC20(path[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
                amountIn,
                amountOut,
                path,
                sender,
                deadline
            );
        } else if (option == 1) {
            IERC20(path[0]).transferFrom(sender, address(this), amountIn);
            IERC20(path[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(
                amountIn,
                amountOut,
                path,
                sender,
                deadline
            );
        } else if (option == 2) {
            require(msg.value > 0, 'Invalid Eth amount.');
            require(amountIn == msg.value, 'Invalid input amounts.');
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactETHForTokens{ value: msg.value }(
                amountOut,
                path,
                sender,
                deadline
            );
        } else {
            revert('Invalid option.');
        }

        amountOut = amounts[amounts.length-1];
        emit BeeSwap(sender, path[0], path[path.length - 1], amountIn, amountOut, block.timestamp);
    }

    function getPrice(uint256 amountA, address[] memory path) public view returns (uint256[] memory) {
        return UniswapV2Library.getAmountsOut(factory, amountA, path);
    }

    function getDetails(address _address)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256
        )
    {
        IERC20 erc20 = IERC20(_address);
        string memory name = erc20.name();
        string memory symbol = erc20.symbol();
        uint256 totalSupply = erc20.totalSupply();
        uint256 decimals = erc20.decimals();
        return (name, symbol, totalSupply, decimals);
    }

}
