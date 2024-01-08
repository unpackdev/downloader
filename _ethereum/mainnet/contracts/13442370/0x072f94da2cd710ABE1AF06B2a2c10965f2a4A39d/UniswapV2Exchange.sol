//PDX-License-Identifier: <SPDX-License>
pragma solidity ^0.6.2;

import "./IExchange.sol";
import "./IErc20.sol";
import "./IUniswapV2Factory.sol";

import "./UniswapV2Library.sol";
import "./IUniswapV2Router02.sol";

contract UniswapV2Exchange is IExchange {
    event CalculatePrice(address token, uint256 amount, uint256 price);
    event Buy(address token, uint256 amountOfToken, address addressToSendTokens);
    event Sell(address token, uint256 amountOfTokens, address payable addressToSendEther, uint256 amountToPay);

    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address private constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function calculatePrice(address _token, uint256 _amount) external override returns (uint256) {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(address(factory), WETH9, _token);
        uint256 price = UniswapV2Library.getAmountIn(_amount, reserveA, reserveB);
        emit CalculatePrice(_token, _amount, price);
        return price;
    }

    function buy(
        address _token,
        uint256 _amount,
        address _addressToSendTokens
    ) external payable override {
        _executeSwap(WETH9, _token, _amount, payable(_addressToSendTokens));
        emit Buy(_token, _amount, _addressToSendTokens);
    }

    function sell(
        address _token,
        uint256 _amount,
        address payable _addressToSendEther
    ) external override returns (uint256) {
        require(_amount > 0, "Must pass non 0 token");
        uint256 deadline = block.timestamp + 15;
        IERC20(_token).approve(address(uniswapRouter), _amount); // using 'now' for convenience, for mainnet pass deadline from frontend!
        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            _amount,
            0,
            _getPath(_token, WETH9),
            payable(address(this)),
            deadline
        );
        uint256 myBalance = address(this).balance;

        (bool success, ) = _addressToSendEther.call{value: address(this).balance}("");
        require(success, "refund failed");
        emit Sell(_token, _amount, _addressToSendEther, myBalance);

        return amounts[1];
    }

    function _executeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address payable _addressToSendTokens
    ) internal {
        require(_amount > 0, "Must pass non 0 token");
        require(msg.value > 0, "Must pass non 0 ETH amount");
        uint256 deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uniswapRouter.swapETHForExactTokens{value: msg.value}(
            _amount,
            _getPath(_tokenIn, _tokenOut),
            _addressToSendTokens,
            deadline
        );

        // refund leftover ETH to user
        (bool success, ) = _addressToSendTokens.call{value: address(this).balance}("");
        require(success, "refund failed");
    }

    function _getPath(address _tokenIn, address _tokenOut) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return path;
    }

    receive() external payable {}
}
