//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IUniswap.sol";
import "./IERC20.sol";
import "./Ownable.sol";


contract Swap is Ownable {
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 public sushiswapRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Router02 public shibaswapRouter = IUniswapV2Router02(0x03f7724180AA6b939894B5Ca4314783B0b36b329);

    IERC20 public weth;
    bool public paused;

    receive() external payable {}

    event Deposit(uint256);
    event Withdraw(uint256);
    event SwapPath(uint256 amountIn, uint256 amountOut);

    constructor() {
        weth = IERC20(uniswapRouter.WETH());
        paused = false;
    }

    function deposit() public onlyOwner payable {
        emit Deposit(msg.value);
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success,) = msg.sender.call{ value: amount }(new bytes(0));
        if (success) {
            emit Withdraw(amount);
        }        
    }

    function withdrawToken(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "Invalid amount");
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= amount, "Amount exceeds balance");
        token.transfer(recipient, amount);
    }

    function balance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }


    function _swapTokens(address[] memory path, uint256 amount, uint8 swap_type) internal returns(uint amountOut) {
        require(path.length >= 2, "Invalid length");
        IERC20 token = IERC20(path[0]);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= amount, "Amount exceeds balance");

        IUniswapV2Router02 router;
        if (swap_type == 0) {
            router = uniswapRouter;
        } else if (swap_type == 1) {
            router = sushiswapRouter;
        } else if (swap_type == 2) {
            router = shibaswapRouter;
        }
        token.approve(address(router), amount);
        uint[] memory amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            ~uint256(0)
        );
        require(amounts.length > 0, "Swap failed");
        return amounts[amounts.length - 1];
    }

    function swapPath(address[] memory tokens, uint8[] memory swaps, uint256 amount) public onlyOwner returns(uint amountOut) {
        require(paused == false, "Service is paused");
        require(tokens.length >= 2, "Invalid length");
        require(tokens.length == swaps.length + 1, "Invalid length");

        uint256 length = tokens.length;
        address[] memory path = new address[](length);
        uint8 path_cnt = 0;
        uint256 currentAmount = amount;

        for (uint8 i = 0; i <= length; i++) {
            bool newRouter = false;
            if (i == length) newRouter = true;
            if (i > 1 && i < length) {
                if (swaps[i - 2] != swaps[i - 1]) newRouter = true;
            }
            if (newRouter) {
                address[] memory _path = new address[](path_cnt);
                for (uint8 j = 0; j < path_cnt; j++) {
                    _path[j] = path[j];
                }
                currentAmount = _swapTokens(_path, currentAmount, swaps[i - 2]);
                if (i == length) {
                    emit SwapPath(amount, currentAmount);
                    return currentAmount;
                } else {
                    path[0] = tokens[i - 1];
                    path[1] = tokens[i];
                    path_cnt = 2;
                }
            } else {
                path[path_cnt] = tokens[i];
                path_cnt = path_cnt + 1;
            }
        }
    }

    function setPaused(bool status) public onlyOwner returns(bool) {
        paused = status;
        return paused;
    }
}